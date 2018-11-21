class Office::OrdersController < ApplicationOfficesController

  before_action :set_office
  before_action :set_order, only: [:show, :save_payment, :payment, :confirm, :complete, :cancel, :download, :undo_changes, :menu, :select_item,
    :edit_item, :add_item, :update_item, :remove_item, :complete_order, :update]

  before_action :check_order, only: [:select_item, :edit_item, :add_item, :update_item, :remove_item, :payment, :save_payment,
    :confirm, :complete, :complete_order]

  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end

  def set_order
    @order = Order.where(id: params[:id]).first
    redirect_to "/404" if !@order || !@order.belongs_to?(@office)
  end

  def set_office
    @office = current_user.user_office.office
  end

  def check_order
    #redirect_to current_office_calendars_path if @order && !@order.restaurant_editable?
  end

  def index

  end

  def review
    @order = @order = Order.where(id: params[:id]).first
    @order_review = @order.order_reviews.new(review_params)

    if @order_review.save

      # Trigger notification on order feedback / review
      restaurant = (@order_review.order && @order_review.order.restaurant) ? @order_review.order.restaurant : nil
      Managers::NotificationManager.trigger_notifications([116], [@office, @order_review, @order_review.order, @order.appointment, @order.sales_rep, restaurant])

      if @order_review.presentation && @order_review.completion && @order_review.food_quality
        flash[:success] = "Order Review has been created!"
        redirect_to current_office_calendars_path
      else
        render :json => {overall: @order_review.overall} and return
      end
    else
      render :json => {success: false, general_error: "Unable to create order review at this time due to the following errors:", errors: @order_review.errors.full_messages}, status: 500
      return
    end
  end

  def show
    if @order
      @order_review = OrderReview.new
      @appointment = @order.appointment
      if @appointment.food_ordered?
        @order_review = @order.active_review('Office') || OrderReview.new(:order_id => @order.id)
      end
    end
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/orders/' + @order.om_order_modal(params[:most_recent_order]), locals:{appointment: @appointment, order_review: @order_review}, :layout => false, :formats => [:html]) }
      end
    else

    end
  end

  def download
    respond_to do |format|
      format.csv do
        man = Managers::CsvManager.new
        csv_data = man.generate_order_detail(@order)
        unless !man.errors.any?
          flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
          redirect_to rep_orders_path(order: @order.id) and return
        end
        send_data csv_data, 
              :type => 'text/csv', 
              :disposition => "attachment; filename=Order_#{@order.order_number}.csv"
      end
      format.pdf do
        if @order
          #@rep_order_review = @order.active_rep_review(current_user) || OrderReview.new
          @office_order_review = @order.active_review('Office')
          appointment = Appointment.find(params[:current_appointment_id]) if params[:current_appointment_id].present?
        end
        ah = ApplicationController.helpers
        pdf = WickedPdf.new.pdf_from_string(
          render_to_string(partial: 'shared/pdf/rep_om_order_detail', :layout => 'pdf', locals:{ah: ah, order: @order}, :formats => [:html]))
        send_data pdf, filename: "Order_#{@order.order_number}.pdf", type: "application/pdf", :disposition => 'inline'
      end
    end
  end    


  def cancel
    #if order is with a non lp office, delete the appointment
    @appointment = @order.appointment

    if (!@order.appointment.appointment_slot && @order.update(:status => 'inactive', :updated_by_id => @modifier_id) && @order.appointment.update(:food_ordered => false, :restaurant_id => nil, :status => 'inactive')) ||
       (@order.appointment.appointment_slot && @order.update(:status => 'inactive', :updated_by_id => @modifier_id) && @order.appointment.update(:food_ordered => false, :restaurant_id => nil))
      @order.line_items.update_all(:status => 'deleted')

      flash[:success] = "Order has been canceled."
      if params[:redirect_to].present?
        redirect_to_tab(params[:redirect_to], @order.office.id)
      else
        redirect_back(fallback_location: root_path)
      end
    else
      render :json => {success: false, general_error: "Unable to cancel order due to the following errors or notices:", errors: @order.errors}, status: 500
      return
    end
  end

  def undo_changes
    @order.line_items.where(:status => 'draft').update(:status => 'deleted')
    @order.update_total(current_user)
    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first    
    session[:cart].delete(cached_order) if cached_order
    
    redirect_to select_food_office_appointment_path(@order.appointment)
  end


    #used to show a single menu and it's items from order flow
  def menu
    if @xhr
      partial = 'office/appointments/components/filtered_menu_items'

      #nil menu == full menu
      menu = nil
      if params[:menu_id].present?
        menu = Menu.find(params[:menu_id])
      end
      restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id].present?
      raise "Unable to find restaurant with the provided ID" unless restaurant
      render json: {templates: {
          targ__filtered_menu_items: (render_to_string :partial => partial, locals:{restaurant: restaurant, menu: menu}, :layout => false, :formats => [:html])
        }
      }
    else
    end
  end

  def select_item # Popup to select and add details for an item, to an order

    item = MenuItem.find(params[:menu_item_id])

    @line_item = LineItem.new(orderable: item, quantity: 1)
    @url = add_item_office_order_path(@order)
    render json: { html: (render_to_string :partial => 'rep/orders/components/select_item', locals: {item: item, order: @order, user: current_user}, :layout => false, :formats => [:html])
                  }

  end

  def edit_item

    @line_item = LineItem.find(params[:line_item_id])
    @url = update_item_office_order_path(@order, line_item_id: @line_item.id)
    render json: { html: (render_to_string :partial => 'rep/orders/components/edit_item', locals: {line_item: @line_item, order: @order, user: current_user}, :layout => false, :formats => [:html])
                  }
  end

  def add_item # Adds an item to an existing order

    appointment = @order.appointment

    @line_item = LineItem.new(line_item_params)
    @line_item.order_id = @order.id

    menu_item = MenuItem.find(params[:line_item][:orderable_id])

    @line_item.cost_cents = @line_item.orderable.retail_price_cents.to_i * (@line_item.quantity || 1)
    @line_item.unit_cost_cents = @line_item.orderable.retail_price_cents.to_i
    @line_item.created_by = current_user
    @line_item.people_served = menu_item.people_served
    @line_item.category = menu_item.category
    if @order.active? && session[:cart].select{|order| order['order_id'] == @order.id}.any?
      @line_item.status = 'draft'
      @line_item.save!
      @cached_order  = session[:cart].select{|order| order['order_id'] == @order.id}.first
      @cached_order['line_items'] << @line_item.id
    else
      @line_item.save!
    end
    sub_option_ids = params[:menu_item_sub_options] || []
    sub_items = MenuSubItemOption.where(id: sub_option_ids)
    sub_items.each do |option|
      if @cached_order
        status = "draft"
      else
        status = "active"
      end
      sub_option_params = { order_id: @order.id,
                            quantity: @line_item.quantity,
                            orderable_id: option.id,
                            orderable_type: 'MenuSubItemOption',
                            cost_cents: (@line_item.quantity || 1) * (option.price_cents || 0),
                            unit_cost_cents: (option.price_cents || 0),
                            created_by: current_user,
                            parent_line_item_id: @line_item.id,
                            status: status }

      item = LineItem.new(sub_option_params)
      item.save!
      @cached_order['line_items'] << item.id if @cached_order
    end

    #@order.update_total

    redirect_to select_food_office_appointment_path(appointment)

  end

  def update
    tip = nil
    if params[:order][:tip_cents].present?
      tip  = params[:order][:tip_cents].to_f
      tip *= 100
    end
    previous_tip = @order.tip_cents
    if !session[:impersonator_id].present? && (@order.total_cents - previous_tip + tip) > @order.authorized_amount_cents(true)
      render :json => {success: false, 
        general_error: "The order total cannot exceed the authorized amount of #{ApplicationController.helpers.precise_currency_value(@order.authorized_amount_cents)}!"}, 
        status: 500
      return
    end
    unless @order.update(:tip_cents => tip)
      render :json => {success: false, general_error: "Unable to update order due to the following errors or notices:", errors: @order.errors}, status: 500
      return
    end
    @order.update_total(current_user)

    if @order.is_past_order
      #todo send notif for office updating tip post delivery
    end
    
    flash[:success] = "Order has been updated!"

    if params[:redirect_to].present?
      redirect_path = rep_orders_path(order: @order.id)
    else
      redirect_back(fallback_location: root_path) and return
    end
    redirect_to redirect_path and return
  end


  def update_item

    return_path = params[:return_path] || 'select_food'

    appointment = @order.appointment

    @line_item = LineItem.find(params[:line_item_id])

    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    if cached_order
      cached_order['line_items'].delete(params[:line_item_id].to_i)
      cached_order['line_items'].reject! {|item| @line_item.sub_line_items.pluck(:id).include?(item) }
      @line_item = LineItem.new(@line_item.attributes.except("id", "created_at", "updated_at"))
      status = 'draft'
    else
      status = 'active'
    end

    if @line_item.update(line_item_params)
      @line_item.cost_cents = @line_item.orderable.retail_price_cents.to_i * (@line_item.quantity || 1)
      @line_item.unit_cost_cents = @line_item.orderable.retail_price_cents.to_i
      @line_item.status = status
      if @line_item.save
        sub_option_ids = params[:menu_item_sub_options] || []
        sub_items = MenuSubItemOption.where(id: sub_option_ids)
        new_sub_items = []
        sub_items.each do |option|
          sub_option_params = { order_id: @order.id,
                                quantity: @line_item.quantity,
                                orderable_id: option.id,
                                orderable_type: 'MenuSubItemOption',
                                cost_cents: (@line_item.quantity || 1) * (option.price_cents || 0),
                                unit_cost_cents: (option.price_cents || 0),
                                created_by: current_user,
                                parent_line_item_id: @line_item.id,
                                status: status }

          new_sub_items << LineItem.new(sub_option_params)
        end

        #### too doo, delete line items wrap in rollback ####
        ActiveRecord::Base.transaction do
          if @line_item.sub_line_items.update_all(:status => 'deleted')
            @line_item.sub_line_items << new_sub_items            
            cached_order['line_items'] << @line_item.id if cached_order
            cached_order['line_items'] += new_sub_items.pluck(:id) if cached_order
          else
            raise ActiveRecord::Rollback
          end
        end
      end
      #@order.update_total
    else

    end
    redirect_to select_food_office_appointment_path(appointment)
  end

  def remove_item

    return_path = params[:return_path] || 'select_food'

    appointment = @order.appointment

    @line_item = LineItem.find(params[:line_item_id])

    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    if cached_order
      cached_order['line_items'].delete(params[:line_item_id].to_i)
      cached_order['line_items'].reject! {|item| @line_item.sub_line_items.pluck(:id).include?(item) }
    else      

      if @line_item.sub_line_items.count > 0
        @line_item.sub_line_items.destroy_all
      end

      @line_item.update(:status => 'deleted')

      #@order.update_total
    end
    redirect_to select_food_office_appointment_path(appointment)

  end
  # The current overall calendar for a single rep, across all offices
  def current

  end

  def payment
    redirect_to current_office_calendars_path and return if !@order.active? && !@order.draft?
    redirect_to confirm_office_order_path(@order) if @order.authorized? && !session[:impersonator_id].present?
    #grab list of active payment methods, or if the orders.payment_method is 'archived', grab that
    @payment_methods = current_user.payment_methods.where(status: ["active"])
                        .or(current_user.payment_methods.where(:id => @order.payment_method_id, :status => 'archived'))
  end

  def save_payment
    # Need to check for existing_payment_method_id.present?
    # -- if present, assign order.payment_method_id to the existing ID, and do not create any new payment method
    # -- if not present, validate and create new payment method and attach to order

    # If successful...
    @payment_manager = Managers::PaymentManager.new(current_user, nil, nil)
    payment_method_id = (params[:order][:payment_method_id].to_i if params[:order].present?) || 0
    #if they want to save a new card
    if params[:save_method].present? && payment_method_id == 0
      payment_method_id = @payment_manager.create_stripe_card(params[:card_token], params[:default], params[:order][:payment_method], true, "active")
      unless payment_method_id.present?
        render :json => {success: false, general_error: "Unable to add payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
        return
      end
    #if they dont want to save a new card, pass "archived" status to create_stripe_card so mark new payment method as archived
    elsif !params[:save_method] && payment_method_id == 0
      payment_method_id = @payment_manager.create_stripe_card(params[:card_token], params[:default], params[:order][:payment_method], true, "archived")
      unless payment_method_id.present?
        render :json => {success: false, general_error: "Unable to add payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
        return
      end
    elsif params[:payment_method_id].present?
      payment_method_id = params[:payment_method_id]
    end
    @order.update!(:payment_method_id => payment_method_id, :updated_by_id => @modifier_id)
    redirect_to confirm_office_order_path(@order)
  end

  def confirm
    redirect_to current_office_calendars_path and return if (!@order.active? && !@order.draft?) || (@order.is_past_order)
    redirect_to payment_office_order_path(@order) and return unless ["active", "archived"].include?(@order.payment_method.status)
    @appointment = @order.appointment
    @cached_order = nil
    if @order.active?
      @cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    end
    if @cached_order && @cached_order['line_items']
      @line_items = LineItem.find(@cached_order['line_items']) 
      @cached_items = @line_items
    else
      @cached_items = nil
      @line_items = @order.line_items
    end
  end

  def complete    
    @edit_order = params[:edit].present?
  end

  def complete_order

    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first

    if cached_order
      if !session[:impersonator_id].present? && @order.authorized_amount_cents(true) &&
        @order.calced_total_cents(LineItem.find(cached_order['line_items']), current_user, params[:order][:tip_cents]) > @order.authorized_amount_cents(true)

        flash[:error] = "The order total cannot exceed the authorized amount of #{ApplicationController.helpers.precise_currency_value(@order.authorized_amount_cents)}!"
        redirect_to request.referrer and return
      end
      @order.line_items = LineItem.find(cached_order['line_items'])
      @order.line_items.update(:status => 'active')
      session[:cart].delete(cached_order)
    else
      @order.line_items.where(:status => 'draft').update(:status => 'active')
    end

    if @order.appointment.internal?
      @edit_order = true if @order.active?
      if params[:order][:tip_cents].present?
        params[:order][:tip_cents] = params[:order][:tip_cents].to_f
        params[:order][:tip_cents] *= 100
      end
      @order.assign_attributes(order_params)
      @order.updated_by_id = @modifier_id
      @order.save!
      if !@order.update_total(current_user)
        flash[:error] = @order.errors.full_messages.first
        redirect_to request.referrer and return
      end
      appointment = @order.appointment
      if appointment
        appointment.food_ordered = true
        appointment.will_supply_food = nil
        appointment.bring_food_notes = nil
        appointment.status = 'active'
        appointment.restaurant_confirmed_at = nil if @edit_order
        appointment.save
        if @edit_order
           Managers::NotificationManager.trigger_notifications([121], 
            [@order, @order.restaurant, appointment, appointment.sales_rep, appointment.office], {poc: current_user.poc_info})
        else
          # Trigger food ordered notifications to all parties involved
          #Managers::NotificationManager.trigger_notifications([119], [appointment, appointment.office, appointment.appointment_slot, @order, @order.restaurant])
        end

      end
    else
      # Save final post
      @order.update!(:status => 'active', :updated_by_id => @modifier_id)
      @order.update_total(current_user)
      appointment = @order.appointment
      if appointment
        appointment.recommended_cuisines = nil
        appointment.status = 'active'
        appointment.save

        # Trigger food ordered notifications to all parties involved, order recommendation
        Managers::NotificationManager.trigger_notifications([105], [appointment, appointment.sales_rep, appointment.office, appointment.appointment_slot, 
          @order, @order.restaurant])
      end
    end
    redirect_to complete_office_order_path(@order, edit: @edit_order)
  end

  private
  def review_params
    params.require(:order_review).permit(:overall, :status, :reviewer_id, :reviewer_type, :comment, :created_by_id,
     :food_quality, :presentation, :completion, :on_time, :order_id)
  end
  def order_params
    params.require(:order).permit(:status, :rep_notes, :tip_cents, :office_notes)
  end

  def line_item_params
    params.require(:line_item).permit(:quantity, :notes, :orderable_type, :orderable_id)
  end
end
