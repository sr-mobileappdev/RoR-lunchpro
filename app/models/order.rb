class Order < ApplicationRecord
  include LunchproRecord
  attr_accessor :restaurant_cancelled

  belongs_to :sales_rep
  belongs_to :appointment
  has_one :office, through: :appointment
  belongs_to :restaurant
  belongs_to :payment_method
  belongs_to :user, foreign_key: "created_by_user_id"
  belongs_to :created_by_user, class_name: 'User'

  has_many :order_reviews
  has_many :line_items

  has_many :order_transactions
  has_many :transactions, class_name: 'OrderTransaction'

  after_create :update_total
  after_create :set_idempotency_key
  after_create :set_order_number

  accepts_nested_attributes_for :appointment

  # -- Validates
  validates_presence_of :sales_rep, :unless => lambda { self.appointment.internal? }# -- JL: Can't validate restaurant as we have to create the order initially without a restaurant until the restaurant is selected #, :restaurant
  validates_presence_of :appointment
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  # These validations should check before final processing
  validate :commit_validations, :on => :update
  before_save :flag_for_notifications

  after_save :process_refund
  after_save :process_cancelation_fee
  after_save :change_payment_method
  after_save :trigger_notifications


  #used to refund authorization or capture amount if order is cancelled
  def process_refund
    if @notify_order_cancelled
      user = User.find(created_by_user_id) if created_by_user_id
      if authorized? && !captured?
        #TODO handle logic if order was created by admin

        man = Managers::PaymentManager.new(user, self, payment_method)
        man.refund_authorization
      elsif captured?
        #TODO handle logic if order was created by admin

        man = Managers::PaymentManager.new(user, self, payment_method)
        man.refund
      end
    end
  end
  def process_cancelation_fee
    if @notify_order_cancelled
      if !cancellable?
        user = User.find(created_by_user_id) if created_by_user_id

        #TODO handle logic if order was created by admin
        man = Managers::PaymentManager.new(user, self, self.payment_method)
        man.charge_cancellation
      end
    end
  end

  def flag_for_notifications
    @notify_order_cancelled = false
    @notify_order_created = false
    if !self.restaurant_cancelled && self.status_changed? && self.status_was == 'active' && ['inactive', 'deleted'].include?(self.status) && !self.recommended_by_id
      @notify_order_cancelled = true
    elsif ((self.status_changed? && self.status_was == 'draft' && self.status == 'active') || (self.new_record? && self.status == 'active')) && !self.recommended_by_id
      @notify_order_created = true
    elsif self.payment_method_id_changed? && self.payment_method_id_was
      @change_payment_method = true
      @old_payment_method_id = self.payment_method_id_was
    end
  end

  def trigger_notifications
    begin
      #if order is being cancelled
      if @notify_order_cancelled
        #if order is an internal office order
        if !self.sales_rep_id && self.appointment.appointment_type == 'internal'
           Managers::NotificationManager.trigger_notifications([120], [self, self.restaurant, self.appointment, self.appointment.office])

        #else if order belongs to rep
        else
          Managers::NotificationManager.trigger_notifications([206], [self, self.restaurant, self.appointment, self.appointment.office, self.sales_rep])
        end

        @notify_order_cancelled = false
      elsif @notify_order_created
        #if order is an internal office order
        if !self.sales_rep_id && self.appointment.appointment_type == 'internal'
          Managers::NotificationManager.trigger_notifications([119], [self, self.restaurant, self.appointment, self.appointment.office, self.appointment.appointment_slot])

        #else if order belongs to rep
        else
          Managers::NotificationManager.trigger_notifications([203], [self,  self.sales_rep, self.restaurant, self.appointment, self.appointment.office,
            self.appointment.appointment_slot])
        end
        @notify_order_created = false
      end
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end

  def change_payment_method
    if @change_payment_method
      user = User.find(created_by_user_id) if created_by_user_id
      if authorized? && !captured?
        #TODO handle logic if order was created by admin
        user = PaymentMethod.find(@old_payment_method_id).user
        man = Managers::PaymentManager.new(user, self, payment_method)
        man.refund_authorization
        man.authorize
      elsif captured?
        #TODO handle logic if order was created by admin
        man = Managers::PaymentManager.new(user, self, payment_method)
        man.refund
      end
    end
  end


  def create_validations
    if appointment.present? && !appointment.upcoming?
      self.errors.add(:base, "Cannot create order for a past appointment")
    end
    return self.errors.count == 0
  end

  def update_validations
    return self.errors.count == 0
  end

  def commit_validations
    true
  end
  # --


  def exceeds_budget?(calced_per_person_cents = nil)
    return false if !appointment.office_id || !sales_rep_id
    osr = OfficesSalesRep.where(:sales_rep_id => sales_rep_id, :office_id => appointment.office_id, :status => 'active').first

    if per_person_budget_cents == nil
      return false
    end

    if calced_per_person_cents && per_person_budget_cents
      calced_per_person_cents > per_person_budget_cents
    else
      per_person_cost_cents > per_person_budget_cents
    end
  end

  def per_person_budget_cents
    return 0 if !appointment.office_id || !sales_rep_id
    osr = OfficesSalesRep.where(:sales_rep_id => sales_rep_id, :office_id => appointment.office_id, :status => 'active').first
    budget_limit = osr.per_person_budget_cents if osr

    if !budget_limit
      budget_limit = sales_rep.per_person_budget_cents
    end
    budget_limit
  end
  #- misc
  def food_selected?
    self.line_items.active.any?
  end

  def delivery_date
    if time = appointment.appointment_time(true)
      time.strftime("%a, %b %e")
    else
      ""
    end
  end

  def delivery_date_and_time
    return nil if !appointment
    "#{(appointment.appointment_time(true) - 15.minutes).strftime('%m/%d/%Y @ %k:%M%P')}"
  end

  def sales_rep_name_phone
    if sales_rep && sales_rep.sales_rep_phone
      "#{sales_rep.display_name}: #{ApplicationController.helpers.format_phone_number_string(sales_rep.sales_rep_phone)}"
    elsif sales_rep
      "#{sales_rep.display_name}: No Phone"
    else
      "No Sales Rep"
    end
  end

  def order_location
    origin = "Unknown"
    office_location = Office.near('Austin, TX, US', 100)
    if office_location.include?(office)
      origin = "Austin"
    else
      origin = "Unknown"
    end
    if origin == "Unknown"
      office_location = Office.near('Dallas, TX, US', 100)
      if office_location.include?(office)
        origin = "Dallas"
      else
        origin = "Unknown"
      end
    end
    origin
  end

  ##used to determine if the order belongs to the current entity
  def belongs_to?(entity)
    return false if !entity

    if entity.kind_of?(Restaurant)
      entity.orders.include?(self)
    elsif entity.kind_of?(SalesRep)
      (sales_rep && sales_rep == entity) || (appointment && appointment.sales_rep &&
        appointment.sales_rep == entity) && !recommended_by_id
    elsif entity.kind_of?(Office)
      return true if created_by_user && created_by_user.space_admin?
      (entity.users.pluck(:id).include?(created_by_user_id))
    else
      false
    end
  end

  #used to determine whether or not the order can be cancelled without a cancellation_fee
  def cancellable?
    return if !appointment
    (appointment.appointment_time > (Time.now.utc + restaurant.cancel_until_hours.hours)) ||
    restaurant.late_cancel_fee_cents == 0 || appointment.appointment_time < Time.now.utc
  end

  #used to determine if order is still editable
  def editable?
    if appointment && appointment.appointment_slot
      Time.now.utc < (appointment.appointment_end_time + 3.hours).asctime.in_time_zone("UTC")
    else
      Time.now.utc < (appointment.appointment_time + 3.hours).asctime.in_time_zone("UTC")
    end
  end

  #used to determine if order is editable
  def restaurant_editable?
    if appointment && appointment.office && restaurant
      (appointment.appointment_time > (Time.now.utc + restaurant.edit_until_hours.hours)) &&
      editable?
    else
      false
    end
  end


  def restaurant_cancellable?
    return if !appointment
    (((appointment.appointment_time - 15.minutes) > (Time.now.utc + 4.hours) && restaurant_confirmed) || !restaurant_confirmed)
  end

  #used to determine the position of the order in the list of orders,
  #ex, this order is the 3rd order the user has placed
  def self.user_order_number(customer, order)
    return nil if !order || !customer
    order_list = all.select{|order| order.appointment && (['active', 'completed'].include?(order.status) || order.cancelled?) &&
    order.customer && order.customer == customer}.sort_by{|order| order.created_at}

    if order_list.any?
      i = order_list.pluck(:id).index(order.id)
      return (i + 1) if i
    else
      nil
    end
  end


  def self.sum_of_order_totals(orders = [], attrib = nil)
    return nil if !orders.any? || !attrib
    orders.sum(&attrib)
  end

  def customer
    return appointment.sales_rep if appointment && appointment.sales_rep
    if created_by_user
      created_by_user
    else
      appointment.created_by_user || nil
    end
  end

  def customer_name
    return nil if !appointment
    if appointment.sales_rep_id
      appointment.sales_rep.full_name if appointment.sales_rep
    else
      if created_by_user
        created_by_user.display_name
      else
        appointment.created_by_user ? appointment.created_by_user.display_name : "Name Unavailable"
      end
    end
  end

  def customer_phone
    return nil if !appointment
    if appointment.sales_rep_id
      appointment.sales_rep.phone_record || appointment.sales_rep.user.primary_phone || "Phone Unavailable"
    else
      if created_by_user
        created_by_user.primary_phone
      else
        appointment.created_by_user ? appointment.created_by_user.primary_phone : "Phone Unavailable"
      end
    end
  end

  def customer_email
    return nil if !appointment
    if appointment.sales_rep_id
      appointment.sales_rep.email("business") || appointment.sales_rep.user.email|| "Email Unavailable"
    else
      if created_by_user
        created_by_user.email
      else
        appointment.created_by_user ? appointment.created_by_user.email : "Email Unavailable"
      end
    end
  end

  def calc_tip(user = nil, cached_items = nil)
    return nil if !user
    if user.sales_rep
      tip_percent = (user.sales_rep.default_tip_percent / 10000.0) if user.sales_rep.default_tip_percent
    end
    tip_percent = 0.15 if !tip_percent
    if cached_items.kind_of?(Array)
      initial_tip = calced_subtotal_cents(cached_items) * (tip_percent)
      return max_tip_amount_cents if user.sales_rep && user.sales_rep.max_tip_amount_cents && initial_tip > user.sales_rep.max_tip_amount_cents
      initial_tip
    else
      initial_tip = calced_subtotal_cents(cached_items) * (tip_percent)
      return max_tip_amount_cents if user.sales_rep && user.sales_rep.max_tip_amount_cents && initial_tip > user.sales_rep.max_tip_amount_cents
      initial_tip
    end
  end

  def self.non_lp_orders_for_tomorrow
    self.joins(appointment: [:office]).where("orders.status = 1 and appointment_id is not null and appointments.status = 1 and appointments.office_id is not null
      and offices.internal = false and appointments.appointment_on = ? ", Time.now + 1.day)
  end

  #used to determine if current user has an active review for an order
  def active_rep_review(user)
    order_reviews.where(:status => 'active', :reviewer_type => "SalesRep", :reviewer_id => user.sales_rep.id).first || nil
  end

  #used to determine if another entity type or user has an active review for an order
  def active_review(type)
    order_reviews.where(:status => 'active', :reviewer_type => type).first || nil
  end

  #used in orders#show to determine which modal to display
  def rep_order_modal(most_recent_order)
    if appointment.appointment_time(true) < Time.now.in_time_zone(appointment.office.timezone)
      if most_recent_order
        "rep_most_recent_past_order"
      else
        "rep_past_order"
      end
    else
      "rep_current_order"
    end
  end

  def om_order_modal(most_recent_order)
    if appointment.appointment_time(true) < Time.now.in_time_zone(appointment.office.timezone)
      if most_recent_order
        "om_most_recent_past_order"
      else
        "om_past_order"
      end
    else
      "om_current_order"
    end
  end
  #-

  def is_tip_modifiable?

  end

  def self.create_order_from_recommendation(rec, current_user, draft_line_items = false)
    return if !rec
    rec = rec.clone
    rec.appointment.orders.where(:status => 'draft', :recommended_by_id => nil).update(:status => 'deleted')
    new_order = Order.new(rec.attributes.except("id","order_number", "created_by_user_id", "created_at", "updated_at", "status", "idempotency_key", "recommended_by_id"))
    new_order.update(:created_by_user_id => current_user.id, :status => 'draft')
    new_line_items = rec.line_items.to_a
    new_line_items.each do |item|
      if !item.parent_line_item_id
        new_item = LineItem.new(item.attributes.except("order_id", "id", "parent_line_item_id"))
        new_item.order_id = new_order.id
        new_item.save!
        if item.sub_line_items.any?
          item.sub_line_items.each do |sub_item|
            new_sub_item = LineItem.create(sub_item.attributes.except("order_id", "id", "parent_line_item_id"))
            new_sub_item.assign_attributes(:parent_line_item_id => new_item.id, :order_id => new_order.id)
            new_sub_item.save!
          end
        end
      end
    end
    new_order.update_total
    new_order
  end

  # Special Scopes ------------

  def self.upcoming(rep_only = true)
    if rep_only
      all.select{|order| order.active? && order.appointment &&  order.appointment.upcoming? && !order.recommended_by_id && order.appointment.sales_rep}.sort_by{|order|
        order.appointment.appointment_time_in_zone}
    else
      all.select{|order| order.active? && order.appointment && order.appointment.upcoming? && !order.recommended_by_id}.sort_by{|order|
        order.appointment.appointment_time_in_zone}
    end
  end

  def self.past(rep_only = true, include_cancelled = true)
    if rep_only
      if include_cancelled
        all.select{|order| order.appointment && order.appointment.sales_rep && ((order.is_past_order && order.completed?) || order.cancelled?)}.sort_by{|order|
          order.appointment.appointment_time_in_zone}
      else
        all.select{|order| order.appointment && order.appointment.sales_rep && ((order.is_past_order && order.completed?))}.sort_by{|order|
          order.appointment.appointment_time_in_zone}
      end
    else
      if include_cancelled
        all.select{|order| (order.is_past_order && order.completed?) || order.cancelled?}.sort_by{|order|
          order.appointment.appointment_time_in_zone}
      else
        all.select{|order| (order.is_past_order && order.completed?)}.sort_by{|order|
          order.appointment.appointment_time_in_zone}
      end
    end
  end

  def self.past_without_cancelled
    all.select{|order| order.appointment && order.appointment.sales_rep && order.is_past_order && !order.cancelled?}.sort_by{|order|
      order.appointment.appointment_time_in_zone}
  end

  def self.drafted
    # Order is a work in progress, not yet submitted. No commitment.
    joins(:appointment).where(status: 'draft').where(Appointment.arel_table[:appointment_on].gt(Time.zone.now.to_date - 1.day))
  end

  def self.submitted
    # Order has been submitted and is ready to be paid at the appropriate time
    where(status: 'active')
  end

  def self.delivered
    where.not(delivered_at: nil).where.not(status: 'deleted')
  end

  def self.completed
    where.not(completed_at: nil).where.not(status: 'deleted')
  end

  def cancelled?
    inactive? && !recommended_by_id
  end


  # --------------
  def confirmed?
    if appointment.restaurant_confirmed_at == nil
      return false
    else
      return true
    end
  end

  def restaurant_confirmed
    self.confirmed?
  end

  def restaurant_unconfirmed
    !self.confirmed?
  end

  def cancelled_by_restaurant
    if cancelled_by_id
      if User.find(cancelled_by_id).space == 'space_restaurant'
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def cancelled_by_admin
    if cancelled_by_id.present?
      if User.find(cancelled_by_id).space == 'space_admin'
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def self.start(params)
    raise "Missing appointment or restaurant" unless params[:appointment_id].present? && params[:restaurant_id].present?
    order = Order.new(params)
    order.sales_rep_id = order.appointment.sales_rep_id
    order.status = "draft"

    order.save

    order
  end

  def self.unconfirmed_by_location(location)
    if location == 'Austin'
      location_offices = Office.near('Austin, TX, US', 100)
    elsif location == 'Dallas'
      location_offices = Office.near('Dallas, TX, US', 100)
    elsif location == 'All Locations'
      location_offices = Office.all
    end
    active.select{|o| location_offices && location_offices.include?(o.office)}.select{|o| !o.confirmed? && (o.appointment.appointment_time_in_zone.past? || (Time.now..2.days.from_now).include?(o.appointment.appointment_time_in_zone))}
  end



  # Api Helpers----



  #-------
  # Date Helpers -------------------------------------------------------------

  def order_date
    appointment.appointment_on
  end#order_date

  def order_time
    appointment.starts_at(true).strftime('%l:%M %p')
  end

  def delivery_time
    # should be 15 minutes prior to appointment starts at
    time = ApplicationController.helpers.slot_time(order_delivery_time)
    return time
  end

  def appointment_timestamp
    # returns a time object in the appt timezone, then we add the slot.starts_at in seconds
    appointment.appointment_time_in_zone
  end#appointment_time

  def created_on
    ApplicationController.helpers.short_date(self.created_at)
  end

  def summary
    if appointment
      ApplicationController.helpers.appointment_summary(appointment)
    end
  end

  def delivery_date
    if appointment
      ApplicationController.helpers.short_date(appointment.appointment_time_in_zone)
    end
  end

  def order_delivery_time
    time = self.appointment.starts_at(true) - (15*60)
    return time
  end

  def location
    if appointment
      ApplicationController.helpers.single_line_address(appointment.office)
    end
  end

  def restaurant_name
    if restaurant
      self.restaurant.name
    end
  end

  def restaurant_name_with_address
    if restaurant
      "#{self.restaurant.is_headquarters? ? 'HQ: ' : ''}#{self.restaurant.name} (#{self.restaurant.display_location_single})"
    end
  end

  def sales_rep_name
   if appointment && appointment.sales_rep.present?
      appointment.sales_rep.first_name + " " + appointment.sales_rep.last_name
   end
  end

  def office_name
    if office
      appointment.office.name
    end
  end
  # Payment Helpers -----------------------------------------------------------

  def able_to_authorize?
    return false if !appointment
    begin
      if appointment.non_lp?
        time_range = (appointment.appointment_time - 30.hours - 10.minutes)..(appointment.appointment_time + 3.hours + 10.minutes)
      else
        time_range = (appointment.appointment_time - 30.hours - 10.minutes)..(appointment.appointment_end_time + 3.hours + 10.minutes)
      end
      # has this order crossed the 24 hour threshold
      time_range.cover?(DateTime.parse(Time.now.utc.to_s))  &&
      # has yet to be auth'd
      !authorized? && active? &&
      # has an idempotency_key
      idempotency_key.present?
    rescue Exception => ex
      Rollbar.error(ex)
      false
    end
  end#able_to_authorize?

  def self.authorizable
    includes(:office).where('status = ? and appointment_id is not null and 
    idempotency_key is not null and (funds_reserved is null or funds_reserved = false)', 1).select{|o| o.in_authorizable_window? }
  end

  def in_authorizable_window?
    if !appointment.appointment_slot_id
      time_range = (appointment.appointment_time - 30.hours - 10.minutes)..(appointment.appointment_time + 3.hours + 10.minutes)
    else
      time_range = (appointment.appointment_time - 30.hours - 10.minutes)..(appointment.appointment_end_time + 3.hours + 10.minutes)
    end
    time_range.cover?(DateTime.parse(Time.now.utc.to_s)) 
  end

  def self.capturable
    includes(:office).includes(:order_transactions).
    includes(appointment: [:appointment_slot]).where('status = 1 and funds_reserved = true and 
      appointment_id is not null and (funds_funded is null or funds_funded = false)').
    select{|o| o.in_capturable_window? && (o.authorized_amount_cents > 0) && Time.now.utc <= (o.order_transactions.select{|ot| 
      ot.transaction_type == 'authorized' && ot.status == 'success'}.sort_by{|ot| ot.created_at}.reverse.first.created_at.utc + 10_075.minutes)
    }

  end

  def in_capturable_window?
    if appointment.non_lp?
      time_range = (appointment.appointment_time + 3.hours)..(appointment.appointment_time + 4.hours + 10.minutes)
    else
      time_range = (appointment.appointment_end_time + 3.hours)..(appointment.appointment_end_time + 4.hours + 10.minutes)
    end
     # has this order crossed the 3 hour threshold, or was missed the last time this captures were triggered
    (time_range.cover?(DateTime.parse(Time.now.utc.to_s)))
  end

  def able_to_capture?
    return false if !appointment
    begin
      if appointment.non_lp?
        time_range = (appointment.appointment_time + 3.hours)..(appointment.appointment_time + 3.hours + 10.minutes)
      else
        time_range = (appointment.appointment_end_time + 3.hours)..(appointment.appointment_end_time + 3.hours + 10.minutes)
      end
       # has this order crossed the 3 hour threshold, or was missed the last time this captures were triggered
      (time_range.cover?(DateTime.parse(Time.now.utc.to_s)) || DateTime.parse(Time.now.utc.to_s) > time_range.end) &&
      !captured? && !refunded?
    rescue Exception => ex
      Rollbar.error(ex)
      false
    end
  end

  def authorized?
    funds_reserved?
  end#authorized?


  def captured?
    funds_funded?
  end#captured?


  def refunded?
    refunded_amount_cents > 0
  end#refunded?


  def auth_failure_count
    order_transactions.authorized.failure.count
  end#auth_failure_count


  def authorized_amount_cents(return_nil = false)
    # LWH NOTE: this should always be the total amount & the funds_reserved amount, but just in case
    t = transactions.authorized.success
    if return_nil
      t.present? ? t.sum(:authorized_amount_cents) - refunded_amount_cents : nil
    else
      t.present? ? t.sum(:authorized_amount_cents) - refunded_amount_cents : 0
    end
  end#authorized_amount_cents


  def captured_amount_cents
    t = transactions.captured.success
    t.present? ? t.sum(:captured_amount_cents) : 0
  end#captured_amount_cents


  def refunded_amount_cents
    t = transactions.refunded.success
    t.present? ? t.sum(:refunded_amount_cents) : 0
  end#refunded_amount_cents


  def remaining_balance
    [ total_cents.to_i - captured_amount_cents, 0 ].max # create a safety net at 0 where we don't go negative
  end#remaining_balance


  def pre_auth_transaction
    transactions.authorized.success.last
  end#pre_auth_transaction


  def captured_transaction
    transactions.captured.success.last
  end#captured_transaction


  def refunded_transaction
    transactions.refunded.success.last
  end#refunded_transaction


  def max_tip_amount_cents
    sales_rep.try(:max_tip_amount_cents)
  end#max_tip_amount_cents
  alias_method :max_tip, :max_tip_amount_cents


  def default_tip_percent
    # default_tip_percent is stored in integer representation of 100ths, (100 = 1%)
    pct = sales_rep.try(:default_tip_percent) || 0
    if pct > 0
      (pct / 100.00) / 100.00 # Reduce this to a percentage of 100 (1% = 0.01)
    else
      0
    end
  end#tip_percent


  def reset_idempotency_key
    # IMPORTANT: this should only be called (and always called) when replacing a failed card with a new card.
    self.idempotency_key = SecureRandom.uuid
    self.save
  end#reset_idempotency_key

  def total_items
    line_items.active.where(:parent_line_item => nil).sum(:quantity)
  end
  def people_served
    items = []
    total_served = 0

    line_items.active.each do |line_item|
      total_served += ((line_item.quantity || 0) * (line_item.people_served || 0))
    end

    total_served
  end

  def per_person_cost_cents
    #served = people_served
    if !appointment.appointment_slot
      served = people_served
      (served > 0) ? subtotal_cents / people_served : 0
    else
      served = appointment.appointment_slot.total_staff_count([], appointment.appointment_on)
      (served > 0) ? subtotal_cents / served : 0
    end
    rescue ZeroDivisionError
      0.0
  end

  def calc_people_served(cached_items = nil)
    return people_served if !cached_items.kind_of?(Array)
    items = cached_items
    total_served = 0
    items.select{|li| !li.parent_line_item_id}.each do |line_item|
      total_served += (line_item.quantity * line_item.people_served)
    end

    total_served

  end

  def calced_tax_cents(cached_items = nil)
    subtotal = calced_subtotal_cents(cached_items)
    if subtotal > 0
      (subtotal + delivery_cost_cents) * (restaurant.sales_tax_percent.to_f / 10000)
    else
      0
    end
  end

  #calculates subtotal and includes draft items
  def calced_subtotal_cents(cached_items = nil)
    subtotal = 0
    items = line_items.select{|li| ['active', 'draft'].include?(li.status) } if !cached_items.kind_of?(Array)
    items = cached_items if cached_items.kind_of?(Array)
    if items.count > 0
      subtotal = 0
      items.each do |li|
        subtotal += li.cost_cents || 0
      end
    end
    subtotal
  end

  def calced_per_person_cost_cents(cached_items = nil)
    if !appointment.appointment_slot
      served = people_served
      if cached_items.kind_of?(Array)
        (served > 0) ? calced_subtotal_cents(cached_items) / calc_people_served(cached_items) : 0
      else
        (served > 0) ? calced_subtotal_cents / people_served : 0
      end
    else
      served = appointment.appointment_slot.total_staff_count([], appointment.appointment_on)
      if cached_items.kind_of?(Array)
        (served > 0) ? calced_subtotal_cents(cached_items) / served : 0
      else
        (served > 0) ? calced_subtotal_cents / served : 0
      end
    end
    rescue ZeroDivisionError
      0.0
  end

  def calced_total_cents(line_items = [], current_user = nil, tip_input = nil)
    return nil if !current_user
    delivery_calc = delivery_cost_cents || 0
    #processing_calc = processing_fee_cents || 0
    sales_tax_calc = calced_tax_cents(line_items) || 0
    if tip_cents > 0
      tip = tip_cents
    else
      tip = calc_tip(current_user).to_f
    end
    tip = tip_input if tip_input
    if line_items.any?
      calced_subtotal_cents(line_items) + tip.to_f + sales_tax_calc + delivery_calc
    else
      calced_subtotal_cents.to_f + tip.to_f + sales_tax_calc + delivery_calc
    end
  end

  def is_past_order
    return appointment.appointment_time(true) < Time.now.in_time_zone(appointment.office.timezone)
  end

  def sales_amount_cents
    delivery_cost_cents + subtotal_cents
  end

  # Calculations -----------------------------------------------------------

  def calced_lunchpro_commission_cents
    ((delivery_cost_cents + subtotal_cents.to_f) * (restaurant.wholesale_percentage.to_f / 10000))
  end

  def calced_processing_fee_cents
    if restaurant.processing_fee_type == 'type_grand_total'
      process_fee = (total_cents * (restaurant.processing_fee_percent.to_f / 10000))
    else
      process_fee = (net_payout_before_processing.to_f * (restaurant.processing_fee_percent.to_f / 10000))
    end
  end
  
  def subtotal_cents_for_restaurant_manager
  	return (subtotal_cents.present? ? subtotal_cents : 0) - (calced_lunchpro_commission_cents.present? ? calced_lunchpro_commission_cents : 0)
  end
  
  def total_cents_for_restaurant_manager
  	return subtotal_cents_for_restaurant_manager + (delivery_cost_cents.present? ? delivery_cost_cents : 0) + (self.status == 'completed' ? (tip_cents.present? ? tip_cents : 0) : (estimated_tip_cents.present? ? estimated_tip_cents : 0))
  end

  #this is called when the order has successfully been completed and transaction has been captured
  def set_commission_and_processing_fees

    return nil if !restaurant

    commission_fee = ((delivery_cost_cents + subtotal_cents.to_f) * (restaurant.wholesale_percentage.to_f / 10000))

    if restaurant.processing_fee_type == 'type_grand_total'
      process_fee = (total_cents * (restaurant.processing_fee_percent.to_f / 10000))
    else
      process_fee = (net_payout_before_processing.to_f * (restaurant.processing_fee_percent.to_f / 10000))
    end

    self.update(:processing_fee_cents => process_fee.ceil, :lunchpro_commission_cents => commission_fee.ceil)
  end

  def commission_fee_cents
    ((delivery_cost_cents + subtotal_cents.to_f) * (restaurant.wholesale_percentage.to_f / 10000))
  end

  def processing_fee_cents

  end

  #what the restuarant will receive
  def net_payout
    return nil if !restaurant
    payout = 0
    if restaurant.withhold_tax
      payout = (total_cents) - (sales_tax_cents)
    else
      payout = (total_cents)
    end
    payout -= ((delivery_cost_cents + subtotal_cents).to_f * (restaurant.wholesale_percentage.to_f / 10000))

    if restaurant.processing_fee_type == 'type_grand_total'
      payout -= (total_cents * (restaurant.processing_fee_percent.to_f / 10000))
    else
      payout -= (payout * (restaurant.processing_fee_percent.to_f / 10000))
    end
    payout.ceil
  end

  #what the restaurant will receive, before processing fee is applied
  def net_payout_before_processing
    return nil if !restaurant
    payout = 0
    if restaurant.withhold_tax
      payout = (total_cents || 0) - (sales_tax_cents)
    else
      payout = (total_cents || 0)
    end
    payout -= ((delivery_cost_cents + subtotal_cents.to_f) * (restaurant.wholesale_percentage.to_f / 10000))

    payout
  end

  def update_total(user = nil)
    subtotal = 0
    subtotal_calc = subtotal

    if line_items.active.count > 0
      subtotal = 0
      line_items.active.each do |li|
        subtotal += li.cost_cents || 0
      end

      subtotal_calc = subtotal
    end

    tip_calc = default_tip_percent * subtotal_calc.to_i # to_i is nilsafe
    tip_calc = [tip_calc, max_tip_amount_cents.to_i].min # don't exceed the max tip amount

    delivery_cost_cents = restaurant.default_delivery_fee_cents if !delivery_cost_cents && restaurant
    delivery_cost_cents = 0 if !delivery_cost_cents

    delivery_calc = delivery_cost_cents || 0
    #processing_calc = processing_fee_cents || 0
    sales_tax_percent = restaurant ? restaurant.sales_tax_percent.to_f : 0
    sales_tax_calc = (subtotal_calc + delivery_cost_cents) * (sales_tax_percent / 10000) || 0
    total_cents_calc = subtotal_calc.to_i + tip_cents.to_i + sales_tax_calc + delivery_calc
    if (authorized? && total_cents_calc > authorized_amount_cents && (!updated_by_id || !User.find(updated_by_id).is_admin?))
      self.errors.add(:base, "The order total cannot exceed the authorized amount of #{ApplicationController.helpers.precise_currency_value(authorized_amount_cents)}!")
      return false
    else
      self.update_attributes(
        delivery_cost_cents: delivery_calc,
        tip_cents: tip_cents || 0,
        estimated_tip_cents: tip_calc,
        sales_tax_cents: sales_tax_calc,
        total_cents: total_cents_calc,
        subtotal_cents: subtotal_calc  )
    end

    if (authorized? && total_cents > authorized_amount_cents && user && !recommended_by_id)
      man = Managers::PaymentManager.new(user, self)
      if man.refund_authorization
        man.authorize
      end
    elsif (able_to_authorize? && !authorized? && user && !recommended_by_id)
      man = Managers::PaymentManager.new(user, self)
      man.authorize
    end
    true
  end#update_total

  # Estimate method factors in estimated tip
  def estimated_total_cents
    delivery_calc = delivery_cost_cents || 0
    sales_tax_calc = sales_tax_cents || 0

    subtotal_cents.to_i + (estimated_tip_cents || 0) + sales_tax_calc + delivery_calc
  end


  def set_order_number
    self.update_column(:order_number, sprintf("OR%.10d", id)) # skip callbacks and validations with update_column
  end#set_order_number


  def self.get_latest_order_per_office_and_sales_rep (office_id, sales_rep_id)
    return Order
    .joins(:appointment => :office)
    .where(:status => Constants::STATUS_ACTIVE, :sales_rep_id => sales_rep_id, :appointments => { :office_id => office_id })
    .order("appointments.appointment_on DESC")
    .first
  end


  # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [])
    params = {}
    scope_strings.each do |scope|
      case scope
        when "unconfirmed"
          params["status"] = "active"
        when "confirmed"
          params["status"] = "active"
        when "past"
          params["status"] = "completed"
        when "inactive"
          params["status"] = "inactive"
        when "not_recommended"
          params["recommended_by_id"] = nil
=begin
        when "active"
          params["status"] = "active"
        when "inactive"
          params["status"] = "inactive"
        when "past"
          params["status"] = "completed"
        when "draft"
          params["status"] = "draft"
        when "confirmed"
          params["status"] = "active"
        when "unconfirmed"
          params["status"] = "active"
=end
        # when "recent"
        #   params["status"] = "inactive"
        #   params["created_at"] = {"operator" => "gt", "condition" => Time.now - 30.days }
      end
    end

    params
  end
  # --

  #

private


  def set_idempotency_key
    # LWH NOTE: this is taken by stripe to ensure that we can't authorize an order twice (ie. double charges)
      # Since we never capture without an auth, this ensures only one auth, one capture per order
    # IMPORTANT: if a card fails altogether for an order and a new card will be used to auth the order,
      # the order should be updated with a new idempotency_key via `reset_idempotency_key`. If not, the charge might fail.
    return false if self.idempotency_key.present?
    self.idempotency_key = SecureRandom.uuid
    self.save
  end#set_idempotency_key


  def order_validations
    # TODO
    # > tip value doesn't exceed max tip
    # > ...
    true
  end#order_validations


end # Order
