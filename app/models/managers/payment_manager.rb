class Managers::PaymentManager
  # Typical process: create_stripe_card > authorize > capture
  # initializing will call stripe and retrieve their customer object for this user. If one doesn't exist, this will create a new one.

  attr_reader :errors, :stripe_customer

  def initialize(user, order=nil, payment_method=nil)
    @errors = []
    @user = user
    @payment_method = payment_method || get_default_payment_method
    @order = order
    set_stripe_customer
  end#initialize




  # Core Methods ------------------------------------------------------------------

  def authorize(description=nil, force=false)
    # LWH NOTE: Stripe will only hold this authorization for 7 days. After 7 days,
      # the auth may not be captured and Stripe will return a status of 'refunded'.
    @errors << "Credit Card Transaction (Hold): No payment method provided" unless @payment_method.present?
    @errors << "Credit Card Transaction (Hold): Order does not meet the qualifications to authorize." unless @order.try(:able_to_authorize?)
    send_payment_notification and return false if @errors.any?

    description ||= "LunchPro #{@order.order_number}"
    padded_amount = (@order.total_cents.to_f * 1.25).round # 25% buffer in the auth

    #padded_amount = (@order.total_cents) # 15% buffer in the auth

    @order_tranx = OrderTransaction.new(
      payment_method_id: @payment_method.id,
      order_id: @order.id,
      authorized_amount_cents: padded_amount,
      transaction_type: 'authorized')

    authorization = Stripe::Charge.create({
      amount: padded_amount,
      currency: "USD",
      customer: @user.stripe_customer,
      source: @payment_method.stripe_identifier, # 'tok_chargeDeclined' # test failure
      description: description,
      capture: false},
      {idempotency_key: @order.idempotency_key})

    rescue => e
      handle_errors(e)
      @errors << e

    else
      @order.update_columns(funds_reserved: true)

    ensure
      if @order_tranx
        @order_tranx.status = authorization.try(:status) == 'succeeded' ? 'success' : 'failure'
        @order_tranx.transaction_identifier = authorization.try(:id)
        @order_tranx.save
      end
      if @errors.any?
        send_payment_notification
        return false
      else
        return true
      end

  end#authorize

  def charge_cancellation
    fee = @order.restaurant.late_cancel_fee_cents
    return if !fee
    @order_tranx = OrderTransaction.new(
      payment_method_id: @payment_method.id,
      order_id: @order.id,
      transaction_type: 'captured',
      captured_amount_cents: fee)

    statement_descriptor = "LunchPro #{@order.order_number}"

    capture = Stripe::Charge.create({
      capture: true,
      amount: fee,
      currency: "USD",
      customer: @user.stripe_customer,
      description: "Cancelation Fee: LunchPro #{@order.order_number}",
      source: @payment_method.stripe_identifier,
      statement_descriptor: statement_descriptor
    })

    rescue => e
      handle_errors(e)
      @errors << e

    else
      true

    ensure
      if @order_tranx
        @order_tranx.status = capture.try(:status) == 'succeeded' ? 'success' : 'failure'
        @order_tranx.transaction_identifier = capture.try(:id)
        @order_tranx.save
      end
      if @errors.any?
        send_payment_notification
        return false
      else
        return true
      end
  end

  def capture(amount=nil, force=false)

    amount ||= @order.remaining_balance

    @errors << "Credit Card Transaction (Charge): Order must be authorized before it may be captured." unless @order.try(:pre_auth_transaction).present?
    @errors << "Credit Card Transaction (Charge): Amount requested to capture exceeds the orders remaining balance." if amount.to_i > @order.remaining_balance # prevent races & overcharges
    @errors << "Credit Card Transaction (Charge): Order does not meet the qualifications to capture."  unless @order.pre_auth_transaction.try(:able_to_capture?)
    send_payment_notification and return false if @errors.any?

    statement_descriptor = "LunchPro #{@order.order_number}" # An arbitrary string to be displayed on the customer’s credit card statement (max: 22 chars)

    @order_tranx = OrderTransaction.new(
      payment_method_id: @order.pre_auth_transaction.payment_method.id,
      order_id: @order.id,
      transaction_type: 'captured',
      captured_amount_cents: amount)

    pre_auth = Stripe::Charge.retrieve(@order.pre_auth_transaction.transaction_identifier)
    capture = pre_auth.capture(amount: amount, statement_descriptor: statement_descriptor)

    rescue => e
      handle_errors(e)
      @errors << e

    else
      @order.update_columns(funds_funded: true)

    ensure
      if @order_tranx
        @order_tranx.status = capture.try(:status) == 'succeeded' ? 'success' : 'failure'
        @order_tranx.transaction_identifier = capture.try(:id)
        @order_tranx.save
      end
      if @errors.any?
        send_payment_notification
        return false
      else
        return true
      end

  end#charge



  def refund(amount=nil, force=nil)
    amount ||= @order.captured_amount_cents
    @errors << "Credit Card Transaction (Refund): Order must be captured before it may be refunded." unless @order.try(:captured_transaction).present?
    @errors << "Credit Card Transaction (Refund): Amount requested to refund exceeds the orders total." if amount.to_i > @order.captured_amount_cents # fwiw, stripe will not allow this; catching it early here
    send_payment_notification and return false if @errors.any?

    @order_tranx = OrderTransaction.new(
      payment_method_id: @order.pre_auth_transaction.payment_method.id,
      order_id: @order.id,
      transaction_type: 'refunded',
      refunded_amount_cents: amount)

    pre_auth = Stripe::Charge.retrieve(@order.pre_auth_transaction.transaction_identifier)
    refund = pre_auth.refund(amount: amount, metadata: {order_id: @order.id, order_number: @order.order_number})

    rescue => e
      handle_errors(e)
      false

    else
      @order.update_columns(funds_reserved: false)
      @order.reset_idempotency_key
      true

    ensure
      if @order_tranx
        @order_tranx.status = refund.try(:status) == 'succeeded' ? 'success' : 'failure'
        @order_tranx.transaction_identifier = refund.try(:id)
        @order_tranx.save
      end
      if @errors.any?
        send_payment_notification
      end

  end#refund

  #used to refund authorized amounts, before  capture
  def refund_authorization(amount = nil, force = nil)
    amount ||= @order.authorized_amount_cents.to_i
    @errors << "Credit Card Transaction (Refund): Order must be authorized before it may be refunded." unless @order.try(:pre_auth_transaction).present?
    @errors << "Credit Card Transaction (Refund): Amount requested to refund exceeds the orders total."  if amount.to_i > @order.authorized_amount_cents # fwiw, stripe will not allow this; catching it early here
    send_payment_notification and return false if @errors.any?

    @order_tranx = OrderTransaction.new(
      payment_method_id: @order.pre_auth_transaction.payment_method.id,
      order_id: @order.id,
      transaction_type: 'refunded',
      refunded_amount_cents: amount)

    pre_auth = Stripe::Charge.retrieve(@order.pre_auth_transaction.transaction_identifier)
    refund = pre_auth.refund(amount: amount, metadata: {order_id: @order.id, order_number: @order.order_number})

    rescue => e
      handle_errors(e)
      false

    else
      @order.update_columns(funds_reserved: false)
      @order.reset_idempotency_key
      true

    ensure
      if @order_tranx
        @order_tranx.status = refund.try(:status) == 'succeeded' ? 'success' : 'failure'
        @order_tranx.transaction_identifier = refund.try(:id)
        @order_tranx.save
      end
      if @errors.any?
        send_payment_notification
      end
  end




  # Getters Setters -------------------------------------------------------------

  def get_default_payment_method
    @user.payment_methods.active.order(:sort_order).first
  end#get_default_payment_method



  def set_default_payment_method
    # if only one card exists, stripe will automatically default that card and this isn't necessary
    return false unless @payment_method.present?

    # get the current user's payments and move @payment_method to the front of the line and update them all with new sort_orders

    current_so = @user.payment_methods.where.not(id: @payment_method.try(:id)).order(:status, :sort_order, updated_at: :desc).lock(true)
    current_so.to_a.unshift(@payment_method).each_with_index.map{|p, i| p.update_columns(sort_order: i+1)}
    @payment_method.reload

    @stripe_customer.default_source = @payment_method.stripe_identifier
    @stripe_customer.save
  end#set_default_payment_method



  def create_stripe_customer
    return false if @user.stripe_customer.present?
    customer = Stripe::Customer.create(email: @user.email, description: @user.display_name, metadata: {user_id: @user.id})
    @user.stripe_customer = customer.id
    if @user.save(validate: false)
      true
    else
      customer.delete # delete the stripe customer it just created
      false
    end
  end#create_stripe_customer



  def create_stripe_card(stripe_token=nil, default=false, params, return_payment_method_id, status)
  
    return false unless stripe_token.present?
    status = "active" if !status
    if stripe_customer_active?
      card = @stripe_customer.sources.create(source: stripe_token)
      set_default_name_address_on_card(card, @user)
      card.save
      @payment_method = PaymentMethod.create(user_id: @user.id, stripe_identifier: card.id, last_four: card.last4, cc_type: card.brand.parameterize.underscore,
        expire_month: card.exp_month, expire_year: card.exp_year, status: status, sort_order: @user.payment_methods.count + 1, city: params[:address_city], state: params[:address_state],
                                            postal_code: params[:address_zip], cardholder_name: params[:name], address_line1: params[:address_line1], address_line2: params[:address_line2], nickname: params[:nickname])

      set_default_payment_method if params[:default] == '1' || params[:default] == true
      if return_payment_method_id
        return @payment_method.id
      else
        true
      end
    elsif stripe_customer_deleted?
      false
    else
      create_stripe_customer ? @stripe_customer.sources.create(source: stripe_token) : false

    end

    rescue => e
      handle_errors(e)
  end#create_stripe_card

  def update_stripe_card(params)
    card = @stripe_customer.sources.retrieve(@payment_method.stripe_identifier)

    card.address_line1 = params[:address_line1] if params[:address_line1].present?
    card.address_line2 = params[:address_line2] if params[:address_line2].present?
    card.address_city = params[:address_city] if params[:address_city].present?
    card.address_state = params[:address_state] if params[:address_state].present?
    card.address_zip = params[:address_zip] if params[:address_zip].present?
    card.name = params[:name] if params[:name].present?
    card.exp_month = params[:exp_month] if params[:exp_month].present?
    card.exp_year = params[:exp_year] if params[:exp_month].present?
    
    set_default_name_address_on_card(card, @user)

    @payment_method.assign_attributes(:nickname => params[:nickname])

    if card.save && @payment_method.save
      set_default_payment_method if params[:default] == true || params[:default] == '1'
    else
      false
    end
    true

    rescue => e
      handle_errors(e)

  end

  def delete_stripe_card(new_default = nil)
    if stripe_customer
      temp = stripe_customer.sources.retrieve(@payment_method.stripe_identifier).delete()

      if new_default
        @payment_method = new_default
        set_default_payment_method
      end
      true
    else
      @errors << 'A stripe customer does not exist for this sales rep'
      false
    end
    rescue => e
      handle_errors(e)
  end


  # Helper Methods -------------------------------------------------------------

  def stripe_customer_active?
    @stripe_customer.try(:object).present?
  end#stripe_customer_exists?



  def stripe_customer_deleted?
    @stripe_customer.try(:deleted).present?
  end#stripe_customer_deleted?



  def card_deleted?
    return nil unless @payment_method.try(:stripe_identifier)
    PaymentMethod.stripe_object(@payment_method.stripe_identifier).try(:deleted).present?
  end#card_deleted?




  # Batch Processing -------------------------------------------------------------

  def self.batch_process_authorizations
    orders_to_authorize.each do |o|
      next if !o.payment_method
      man = Managers::PaymentManager.new(o.payment_method.user, o, o.payment_method)
      man.authorize
    end
  end#batch_process_authorizations

  def self.batch_process_captures
    orders_to_capture.each do |o|
      next if !o.payment_method
      begin
        man = Managers::PaymentManager.new(o.payment_method.user, o, o.payment_method)
        if man.capture

          #set order to complete, and set processing fee cents
          o.update(:status => 'completed', :completed_at => Time.now)
          o.set_commission_and_processing_fees

          if o.appointment.sales_rep
            Managers::NotificationManager.trigger_notifications([402], [o, o.appointment, o.appointment.sales_rep, o.appointment.sales_rep.user])
          elsif o.appointment.internal?
            Managers::NotificationManager.trigger_notifications([402], [o, o.appointment, o.customer, o.appointment.office])
          end
        end
      rescue => ex
        Rollbar.error(ex)
      end
    end
  end

  def self.orders_to_authorize
    # returns an array of Order instances
    # LWH FIXME: decide if lock is a good idea or not    
    orders = Order.authorizable
  end#orders_to_authorize

  def self.orders_to_capture
    # returns an array of Order (pre-auth) Transaction instances
    #orders = Order.capturable
    orders = Order.capturable
  end#orders_to_capture




private

  def send_payment_notification
    return if !@errors.any? || (@order.order_transactions.where(:status == 6).length > 1)
    if @order_tranx
      Managers::NotificationManager.trigger_notifications([421], [@order_tranx, @order, @order.restaurant, @order.appointment, @order.appointment.office])
    else
      Managers::NotificationManager.trigger_notifications([421], [@order, @order.restaurant, @order.appointment, @order.appointment.office], {order_tranx_error: @errors.first,
        order_tranx_time: Time.now})
    end
  end#send_payment_notification



  def handle_errors(e)
    # LWH Note: using `rescue => e` in this models methods to handle the following properly:
    # rescue Stripe::CardError    # Since it's a decline, Stripe::CardError will be caught
    # rescue Stripe::RateLimitError   # Too many requests made to the API too quickly
    # rescue Stripe::InvalidRequestError    # Invalid parameters were supplied to Stripe's API
    # rescue Stripe::AuthenticationError    # Authentication with Stripe's API failed
    # rescue Stripe::APIConnectionError   # Network communication with Stripe failed
    # rescue Stripe::StripeError    # Display a very generic error to the user, and maybe send yourself an email
    # rescue StandardError => e

    ##TODO need to notify someone for this ##
    Rollbar.error(e)
    @errors << e.message
    if @order_tranx.present?
      @order_tranx.error_message = e.message
      @order_tranx.raw_api_response = e.to_json
    end
  end#handle_stripe_errors



  def set_stripe_customer
    if stripe_customer_deleted? || @user.stripe_customer.blank?
      @user.stripe_customer = nil
      create_stripe_customer
    end

    @stripe_customer = Stripe::Customer.retrieve(@user.stripe_customer)

    unless stripe_customer_active?
      raise "Managers::PaymentManager.set_stripe_customer Failed to set stripe customer."
    end

    rescue => e
      handle_errors(e)

  end#set_stripe_customer
  
  def set_default_name_address_on_card(card, user)
	if !card.name.present? && user.present? && user.first_name.present? && user.last_name.present?
		card.name = user.first_name + ' ' + user.last_name
	end
	if !card.address_line1.present?
		card.address_line1 = '8111 Lyndon B Johnson Fwy'
	end
	if !card.address_city.present?
		card.address_city = 'Dallas'
	end
	if !card.address_state.present?
		card.address_state = 'TX'
	end
	if !card.address_zip.present?
		card.address_zip = '75251'
	end
  end

end # Managers::PaymentManager
