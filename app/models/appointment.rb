class Appointment < ApplicationRecord
	# Schema Notes:
		# Office could confirm ON BEHALF OF the rep through a manual confirm button in the UI
		# An appointment can exists internal to an office and won't be shown to reps, and the office can order food for
			# themselves for that internal appointment (appotintment_type [enum] addresses this)
		# Offices can block an appointment slot as well, for one-off cases where an appointment slot shouldn't be made available (appotintment_type [enum] addresses this)
		# May need a simple state machine here for managing the flow of an appointment

  include LunchproRecord
	serialize :starts_at, Tod::TimeOfDay
	serialize :ends_at, Tod::TimeOfDay

	belongs_to :sales_rep
	belongs_to :office
  belongs_to :restaurant # Optional, when rep is bringing own food this is null
	belongs_to :appointment_slot
	belongs_to :created_by_user, class_name: 'User'
  belongs_to :cancelled_by_user, class_name: 'User'

	has_many :sample_requests, dependent: :destroy
	has_many :orders, dependent: :destroy

	enum appointment_type: {standard: 1, internal: 2, block: 3} # Standard is the db default
  enum origin: {web: 1, lunchpad: 2, android: 3, import: 4, ios: 5}

 # validates_presence_of :office, :appointment_slot, :appointment_type, :appointment_on, :starts_at, :ends_at
  validates_presence_of :office, :appointment_type
  validates_presence_of :appointment_on, :starts_at, :if => Proc.new { |o|
  !o.samples_requested.present?}

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  before_create :adjust_for_dst
  before_save :flag_for_notifications
  after_save :trigger_notifications

  def flag_for_notifications
    @notify_appointment_cancelled = false
    
    if self.status_changed? && self.status_was == 'active' && ['inactive', 'deleted'].include?(self.status) && self.cancelled_by_id && self.appointment_type != 'internal' &&
      self.office && self.office.activated? && !self.excluded
        @notify_appointment_cancelled = true
    end
    if self.rep_confirmed_at_changed? && !self.rep_confirmed_at_was
      self.office_confirmed_at = Time.now if !self.office_confirmed_at
    end

    #if rep books an appt with an office that is not a part of their 'MY offices', attach it to my offices
    if ((self.status_changed? && self.status == 'active') || (self.new_record? && self.status == 'active')) &&
      self.sales_rep && self.office && !self.sales_rep.offices.include?(office)
      self.sales_rep.offices_sales_reps << OfficesSalesRep.new(:office_id => self.office.id, :status => 'active',
        :created_by_id => (self.sales_rep.user ? self.sales_rep.user.id : nil))
    end
  end

  def trigger_notifications
    begin
      #if rep appt is being cancelled
      if @notify_appointment_cancelled
        #get active order if exists
        order = self.active_order

        #if rep appt is cancelled by office manager or admin
        if ['space_office'].include?(User.find(self.cancelled_by_id).space)

          if order
            # Trigger Notification 104 - Office: Cancels appointment WITH attached order
            Managers::NotificationManager.trigger_notifications([104], [self, self.office, self.sales_rep, self.appointment_slot, order])
          else
            # Trigger Notification 103 - Office: Cancels appointment WITHOUT attached order
            Managers::NotificationManager.trigger_notifications([103], [self, self.office, self.sales_rep, self.appointment_slot])
          end

        #else if rep appt cancelled by rep
        elsif ['space_sales_rep'].include?(User.find(self.cancelled_by_id).space)
          if order
            # Trigger Notification 204 - Rep: Cancels appointment WITH attached order
            Managers::NotificationManager.trigger_notifications([204], [self, self.office, self.sales_rep, self.appointment_slot, order])
          else
            # Trigger Notification 205 - Rep: Cancels appointment WITHOUT attached order
            Managers::NotificationManager.trigger_notifications([205], [self, self.office, self.sales_rep, self.appointment_slot])
          end
        end
      end
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end

  ##used to determine if the appointment belongs to the current entity
  def belongs_to?(entity)
    return false if !entity

    if entity.kind_of?(SalesRep)
      (sales_rep && sales_rep == entity)
    elsif entity.kind_of?(Office)
      office && office == entity
    else
      false
    end
  end

  def belongs_to
    if sales_rep
      return sales_rep.user if sales_rep.user
      return nil
    end
    return office.manager if office.manager
    User.find(created_by_user_id)
  end

	def self.future
		active.where("appointment_on >= ?", Time.zone.now - 1.day)
	end

  def self.future_hash
    active.select{|appt| appt.appointment_time_in_zone > Time.zone.now}
  end

	def current_order
		Order.where(appointment_id: self.id, :recommended_by_id => nil).where.not(status: ['deleted', 'inactive']).first
	end

  def has_notes?
    office_notes.present? || rep_notes.present? || bring_food_notes.present? || delivery_notes.present?
  end

  def is_sample?
    appointment_slot && appointment_slot.slot_type == 'sample'
  end

  def create_validations
    unless sales_rep_id.present? || title.present? || excluded
      self.errors.add(:base, "You must select a Sales Rep.")
    end
    if !non_lp? && standby_filled? && active?
      self.errors.add(:base, "You are attempting to create a duplicate appointment!")
    end
    if !samples_requested.present? && office.appointments_until && appointment_on > office.appointments_until
      self.errors.add(:base, "This Office isn't accepting appointments on this date.")
    end
  end

  def adjust_for_dst
        Time.zone = "Central Time (US & Canada)"
        if self.appointment_slot.present? && self.appointment_on.present?
			full_date_time = self.appointment_slot.starts_at.on(self.appointment_on)
			if !full_date_time.dst?
				self.starts_at = self.appointment_slot.starts_at + (60 * 60) # one hour
				self.ends_at = self.appointment_slot.ends_at + (60*60) # one hour
			end
		end
  end

  def update_validations
    unless sales_rep_id.present? || title.present? || excluded
      self.errors.add(:base, "You must select a Sales Rep.")
    end
    if !non_lp? && standby_filled? && active?
      self.errors.add(:base, "You are attempting to create a duplicate appointment!")
    end
    if !upcoming?
    	if rep_confirmed_at_was == nil && rep_confirmed_at != nil
    		self.errors.add(:base, "You cannot confirm a past appointment")
    	end
    	if cancelled_at_was == nil && cancelled_at != nil
    		self.errors.add(:base, "You cannot cancel a past appointment")
    	end
    end
  end


  #used to see if an appointment has been filled from standby notification
  def standby_filled?
    if id
      Appointment.where("status = 1 and id != ? and appointment_slot_id = ? and appointment_on = ?", id, appointment_slot_id, appointment_on).any?
    else
      Appointment.where("status = 1 and appointment_slot_id = ? and appointment_on = ?", appointment_slot_id, appointment_on).any?
    end
  end

  #checks if appointment is a duplicate
  def is_duplicate?(in_time_zone = false)
    if in_time_zone
      Appointment.where(:status => 'active', :appointment_on => appointment_on, :sales_rep_id => sales_rep_id).where.not(:id => id).select{|appt| appt.starts_at(true) == starts_at}.any?
    else
      Appointment.where(:status => 'active', :appointment_on => appointment_on, :starts_at => starts_at, :sales_rep_id => sales_rep_id).where.not(:id => id).any?
    end
  end

  #used to create an appt from a standby appt
  def self.fill_standby(appt, sales_rep, web = false)
    return false if !appt || !sales_rep
    appointment = Appointment.new(appt.attributes.except("id", "sales_rep_id", "created_by_user_id", "created_at", "updated_at",
      "cancelled_by_id", "cancelled_at", "cancel_reason"))
    appointment.assign_attributes(:sales_rep_id => sales_rep.id, :created_by_user_id => sales_rep.user.id, :status => 'active')
    if web
      appointment.origin = 'web'
    end
    if appointment.save
      appointment
    else
      false
    end
  end

  def active_order_number
    ord = active_order
    return ord.order_number if ord
  end

  def active_order_id
    ord = active_order
    return ord.id if ord
  end

  def csv_active_order
    orders.select{|o| ['completed', 'active'].include?(o.status) && !o.recommended_by_id}.first    
  end
  
  def active_order
    orders.where(status: ['completed', 'active'], :recommended_by_id => nil).sort_by{|order| order.created_at}.reverse.first
  end

  #used to grab a cancelled order belonging to a cancelled appt
  def cancelled_order
    orders.select{|order| order.cancelled? && order.recommended_by_id == nil }.sort_by{|order| order.created_at}.reverse.first
  end

  def internal?
    appointment_type == "internal"
  end

  def created_by_office?
    self.created_by_user && self.created_by_user.space_office?
  end

  def cancelled?
    cancelled_by_id.present? && cancelled_at.present?
  end

  def canceller
    User.find(cancelled_by_id)
  end

	def appointment_state
		if standard?
			:booked
		elsif internal? || block?
			:internal
		end
	end

	def order_state
		# :ordered, :pending_order
		if food_ordered?
			:ordered
		else
			:pending_order
		end
	end

  ## Used in Appointment modals ##
  def show_select_food?
    !self.food_ordered? && !self.will_supply_food && !self.cuisine_recommended?
  end

  def show_cuisine_recommendation?
    self.cuisine_recommended? && !self.show_select_food? && !self.will_supply_food && !self.food_ordered?
  end

  ## end ##

  def total_budget_for_appointment
    if sales_rep
      office_sales_rep = self.sales_rep.offices_sales_reps.where(:office_id => self.office_id, :status => 'active').first
      if office_sales_rep
        per_person_budget = office_sales_rep.per_person_budget_cents
      else
        per_person_budget = sales_rep.per_person_budget_cents
      end

    end

    if !per_person_budget
      per_person_budget = self.sales_rep.per_person_budget_cents
    end
    total_budget = per_person_budget * (self.appointment_slot.total_staff_count) if per_person_budget
    total_budget = nil if total_budget == 0
    total_budget

  end

	def will_have_food?
		standard?
	end

	def food_ordered?
		self.food_ordered && orders.select{|order| order.active? || order.completed?}.count >= 1
	end

  def show_order_recommendation?
    self.recommended_order.present? && self.recommended_order.active?
  end

  def recommended_order
    self.orders.where(status: ['active', 'draft']).where.not(:recommended_by_id => nil).first
  end

  def cuisine_recommended?
    self.recommended_cuisines.present?
  end

	def upcoming?
		# @TODO Need to determine if we have any additional timezone considerations here
		starts_at.present? && appointment_on.present? && (appointment_time_in_zone > Time.zone.now)
	end

  def past?
    ['active', 'completed'].include?(status) && (appointment_time_in_zone < Time.zone.now)
  end

  def self.past(include_cancelled = true)
    if include_cancelled
      all.select{|appt| (['active', 'completed'].include?(appt.status) && (appt.appointment_time_in_zone < Time.zone.now)) || appt.cancelled?}.
      sort_by{|appointment| appointment.appointment_time_in_zone}
    else
      all.select{|appt| (['active', 'completed'].include?(appt.status) && (appt.appointment_time_in_zone < Time.zone.now))}.
      sort_by{|appointment| appointment.appointment_time_in_zone}
    end
  end

  def self.confirmed_without_food
    active.where.not(rep_confirmed_at: nil).includes(:office).includes(sales_rep: [:user]).includes(:appointment_slot).select{|a| a.appointment_slot && a.appointment_slot.slot_type != 'sample'}.select{|a| a.sales_rep.is_lp? && (a.appointment_time_in_zone.past? || (Time.now.beginning_of_day..2.days.from_now.end_of_day).include?(a.appointment_time_in_zone)) && !a.food_ordered? && !a.bring_food_notes}
  end

  def self.confirmed_without_food_by_location(location)
    if location == 'Austin'
      location_offices = Office.near('Austin, TX, US', 100)
    elsif location == 'Dallas'
      location_offices = Office.near('Dallas, TX, US', 100)
    elsif location == 'All Locations'
      location_offices = Office.all
    end
    confirmed_without_food.select{|a| location_offices && location_offices.include?(a.office)}
  end

  def self.with_declined
    active.includes(:office).includes(sales_rep: [:user]).includes(:appointment_slot).includes(:orders).select{|a| a.appointment_slot && a.appointment_slot.slot_type != 'sample'}.select{|a| a.sales_rep && a.sales_rep.is_lp? && (a.appointment_time_in_zone.past? || (Time.now.beginning_of_day..7.days.from_now.end_of_day).include?(a.appointment_time_in_zone)) && a.cancelled_order.present? && !a.active_order}
  end

  def self.with_declined_by_location(location)
    if location == 'Austin'
      location_offices = Office.near('Austin, TX, US', 100)
    elsif location == 'Dallas'
      location_offices = Office.near('Dallas, TX, US', 100)
    elsif location == 'All Locations'
      location_offices = Office.all
    end
    with_declined.select{|a| location_offices && location_offices.include?(a.office)}
  end

  def self.unconfirmed_by_location(location)
    if location == 'Austin'
      location_offices = Office.near('Austin, TX, US', 100)
    elsif location == 'Dallas'
      location_offices = Office.near('Dallas, TX, US', 100)
    elsif location == 'All Locations'
      location_offices = Office.all
    end
    active.where(rep_confirmed_at: nil).includes(:office).includes(sales_rep: [:user]).select{|a| a.appointment_on && (a.appointment_time_in_zone.past? || (Time.now..2.days.from_now).include?(a.appointment_time_in_zone)) && !a.internal? && location_offices && location_offices.include?(a.office)}
  end

  def self.for_today(location) #confirmed w/ food or bring your own noted

    if location == 'Austin'
      location_offices = Office.near('Austin, TX, US', 100)
    elsif location == 'Dallas'
      location_offices = Office.near('Dallas, TX, US', 100)
    elsif location == 'All Locations'
      location_offices = Office.all
    end
    #Appointment.active.where("appointment_on <= ? AND appointment_on >= ?", Date.today+3.day, Date.today).includes(:office).includes(:appointment_slot).select{|a| location_offices && location_offices.include?(a.office) && (a.bring_food_notes || a.food_ordered? || (a.appointment_slot))} //LP appointments
    Appointment.active.where("appointment_on <= ? AND appointment_on >= ?", Date.today+3.day, Date.today)
  end

  def appointment_location
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

  def self.by_location(location)
    if location
      select{|a| a.office.city == location}
    end
  end

  def user_activated?
    if sales_rep.is_lp?
      if sales_rep.user.invitation_accepted_at
        return true
      else
        return false
      end
    end
  end

	def sales_rep_confirmable?
		!past? && rep_confirmed_at == nil && appointment_time_in_zone < (Time.zone.now + 10.days)
	end

  def office_confirmable?
    office_confirmed_at == nil && appointment_time_in_zone < (Time.zone.now + 72.hours)
  end

  def rep_confirmed
    rep_confirmed_at != nil
  end

  def office_confirmed
    office_confirmed_at != nil
  end

  def restaurant_confirmed
    restaurant_confirmed_at != nil
  end

  def non_lp?
    !appointment_slot.present?
  end

  # Triggers write of confirmation
  def confirm_for_rep!
    self.rep_confirmed_at = Time.now
    self.save
  end

  def confirm_for_office!
    self.office_confirmed_at = Time.now
    self.save
  end

  def confirm_for_restaurant!
    self.restaurant_confirmed_at = Time.now
    self.save
  end

  def upcoming_order?
  	if starts_at.present?
	    return appointment_time(true) > Time.now.in_time_zone(office.timezone)
  	else
  		return false
  	end
  end

  def delivery_time(local = false)
    #default pass back as utc
    #or use office timezone or local timezone and convert time to datetime object with offset of timezone
    if local
      timezone = office.timezone || Time.zone.name
      converted_time = (read_attribute(:starts_at).on appointment_on).asctime.in_time_zone("UTC").in_time_zone(timezone)
      time_minus_15 = converted_time - 15.minutes
      Tod::TimeOfDay(time_minus_15.to_s(:time))
    else
      read_attribute(:starts_at)
    end
  end

  def starts_at(local = false)
    #default pass back as utc
    #or use office timezone or local timezone and convert time to datetime object with offset of timezone
    if local
      timezone = office.timezone || Time.zone.name
      converted_time = (read_attribute(:starts_at).on appointment_on).asctime.in_time_zone("UTC").in_time_zone(timezone)
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:starts_at)
    end
  end

  def ends_at(local = false)
    #default pass back as utc
    #or use office timezone or local timezone and convert time to datetime object with offset of timezone
    if local
      timezone = office.timezone || Time.zone.name
      converted_time = (read_attribute(:ends_at).on appointment_on).asctime.in_time_zone("UTC").in_time_zone(timezone)
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:ends_at)
    end
  end

	def appointment_time(in_zone = false)
		# A combination of the slot and the appointment_on date
    return nil if !starts_at.present?
    if in_zone
      time = starts_at(true)
    else
		  time = starts_at
    end
		date = time.on appointment_on
    if in_zone
      date
    else
      (starts_at(true).on appointment_on).asctime.in_time_zone(office.timezone).in_time_zone('UTC')
    end
	end

  def appointment_end_time(in_zone = false)
    # A combination of the slot and the appointment_on date
    return nil if !ends_at.present?
    if in_zone
      time = ends_at(true)
    else
      time = ends_at
    end

    if in_zone
      date = time.on appointment_on
    else
      (ends_at(true).on appointment_on).asctime.in_time_zone(office.timezone).in_time_zone('UTC')
    end
  end

	def appointment_time_in_zone
		appointment_time(true)
	end

	def appointment_date
		if time = appointment_time(true)
			time.strftime("%A, %b %-d at %l:%M %P")
		else
			""
		end
	end

	def description
		if appointment_slot
			"#{appointment_slot.name}"
		else
			"Appointment"
		end
	end

  def office_name
    "#{office.name}"
  end

  def office_name_phone
    info = ""
    if office
      info += "#{office_name}"
      if office.manager_phone
        info += ": #{office.manager_phone}"
      else
        info += ": No Phone"
      end
    else
      "--"
    end
  end

  def restaurant_name(tbd = false)
    if restaurant
      restaurant.name
    else
      "Unknown" if !tbd
      "TBD"
    end
  end

  def office_location
    "#{office.display_location}"
  end

  def sales_rep_name
    if sales_rep
  	   "#{sales_rep.display_name}"
    end
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

  def organizer_name
    if sales_rep
      "#{sales_rep.display_name}"
    else
      "Internal Appointment"
    end
  end

  def company_name
  	if self.sales_rep && self.sales_rep.company
  		self.sales_rep.company.name
  	else
  		"No Company"
  	end
  end

  def slot_type
    if appointment_slot
      "#{self.appointment_slot.slot_type.capitalize}"
    else
      "Non-LP Office"
    end
  end

  def food_column
    if food_ordered?
      orders = self.orders.where(recommended_by_id: nil)
      if orders.count == 1
        "#{orders.first.order_number}"
      end
    elsif bring_food_notes.present?
      "BYO: #{bring_food_notes}"
    elsif appointment_slot && appointment_slot.slot_type == 'sample'
      "Sample"
    else
      "--"
    end
  end

  def food_restaurant_column
    if food_ordered?
      orders = self.orders.where(recommended_by_id: nil)
      if orders.count == 1
        "#{orders.first.restaurant.name} - #{orders.first.order_number}"
      end
    elsif bring_food_notes.present?
      "BYO: #{bring_food_notes}"
    elsif appointment_slot && appointment_slot.slot_type == 'sample'
      "Sample"
    else
      "Food Information Not Provided"
    end
  end

  def slot_time_type
    string = "#{appointment_time_in_zone.strftime('%l:%M %p')}"
    if appointment_slot
      string += " - #{self.slot_type}"
    end
    string
  end

  def cancelled_by
    if cancelled_order
      if cancelled_order.cancelled_by_restaurant
        "#{cancelled_order.restaurant.name}"
      elsif cancelled_order.cancelled_by_admin
        admin = User.find(cancelled_order.cancelled_by_id)
        "#{admin.display_name}"
      end
    end
  end

  def office_info
    {id: office_id, name: office.name}
  end

  def rep_appointment_partial
    if !sales_rep_confirmable? && !rep_confirmed && upcoming?
      "rep/appointments/components/booked_appointment_detail.html.erb"
    elsif !upcoming?
       "rep/appointments/components/past_appointment_detail.html.erb"
    elsif sales_rep_confirmable? && upcoming?
       "rep/appointments/components/confirmation_pending_appointment_detail.html.erb"
    elsif rep_confirmed && upcoming?
       "rep/appointments/components/confirmed_appointment_detail.html.erb"
    end

  end
  #used to define which modal to display for appointment
  def rep_appointment_modal
    if cancelled_by_id.present? && cancelled_at.present?
      user = User.find(cancelled_by_id)
      if user.present? && (user.space == 'space_office' || user.space == 'space_admin')
        return "canceled_appointment"
      #if cancelled by rep, means its standby
      elsif user.present? && user.space == 'space_sales_rep'
        return "standby_appointment"
      else
        #maybe an appt is no longer available?
        return nil
      end
    end
    if !sales_rep_confirmable? && !rep_confirmed && upcoming?
      "booked_appointment"
    elsif !upcoming?
      "past_appointment"
    elsif sales_rep_confirmable?
      "confirmation_pending_appointment"
    elsif rep_confirmed
      "confirmed_appointment"
    end
  end

  def office_appointment_modal
    if cancelled_by_id.present? && cancel_reason.present?
      user = User.find(cancelled_by_id)
      if user.present? && user.space == 'space_sales_rep'
        return "canceled_appointment"
      else
        #maybe an appt is no longer available?
        return nil
      end
    end
    if internal?
      if !upcoming?
        return "past_internal_appointment"
      else
        return "internal_appointment"
      end
    end
    if excluded
      return "excluded_appointment"
    end
    if !upcoming?
      "past_appointment"
    elsif status == 'pending'
      "pending_appointment"
    elsif !office_confirmable? && !office_confirmed && !title.present?
      "booked_appointment"
    elsif office_confirmable? && !title.present?
      "confirmation_pending_appointment"
    elsif office_confirmed
      "confirmed_appointment"
    end
  end

  #used for calendar to determine legend icon for appt
  def appointment_calendar_key
    if !upcoming?
      "past"
    else
      if (food_ordered? && rep_confirmed) || (!sales_rep_confirmable? && !rep_confirmed) || (will_supply_food)
        "confirmed"
      else
        "booked"
      end
    end
  end


#---- api helpers

  #used in api to combine basic order info and restaurant info
  def orders_with_restaurant
    orders_with_restaurants = []
    orders.where.not(status: ['inactive','deleted']).each do |order|
      orders_with_restaurants << {id: order.id, order_number: order.order_number,status: order.status, rep_notes: order.rep_notes, restaurant_notes: order.restaurant_notes, total_cents: order.total_cents,
        restaurant: order.restaurant ? order.restaurant.restaurant_quick_info : nil}
    end
    orders_with_restaurants
  end

#-------

  def cuisines
    Cuisine.where(:status => 'active', id: recommended_cuisines)
  end

  def diet_restrictions
    appt_restricts = []
    if appointment_slot && appointment_slot.staff_count > 0
      appt_restricts = office.diet_restrictions_offices.to_a    #set appt_restricts to office's diet restricts
      providers = office.providers_available_at(appointment_slot)
      providers.each do |prov|
        prov.diet_restrictions.each do |diet|
          #if provider has a shared restriction with office, or restrict exists in appt_restrict, increment staff count by 1
          temp_restrict = appt_restricts.select {|d| d.diet_restriction_id == diet.id}
          if !temp_restrict.empty?
            temp_restrict.first.staff_count += 1
          else
            #else create new temp restrict and append to appt_restricts
            appt_restricts << Appointment::AppointmentDietRestriction.new(1, diet, self)
          end
        end
      end

    end
    appt_restricts

  end

  def diet_restrictions_api
    appt_restricts = []
    api_restricts = []
    begin
    if appointment_slot.present? && appointment_slot.staff_count > 0
      appt_restricts = office.diet_restrictions_offices.to_a    #set appt_restricts to office's diet restricts
      providers = office.providers_available_at(appointment_slot)
      #loop through available providers and their restrictions
      providers.each do |prov|
        prov.diet_restrictions.each do |diet|
          #if provider has a shared restriction with office, or restrict exists in appt_restrict, increment staff count by 1
          temp_restrict = appt_restricts.select {|d| d.diet_restriction_id == diet.id}
          if temp_restrict.any? && temp_restrict.first.present?
            temp_restrict.first.staff_count = 0 if !temp_restrict.first.staff_count
            temp_restrict.first.staff_count += 1
          else
            #else create new temp restrict and append to appt_restricts
            appt_restricts << Appointment::AppointmentDietRestriction.new(1, diet, self)
          end
        end
      end
      #loop through appt_restricts and assign staff counts to appt slot staff count if restrict staff count is greater
      appt_restricts.select{|r| r.diet_restriction}.each do |appt_restrict|
        if appt_restrict.present?
          if !appt_restrict.staff_count || appt_restrict.staff_count > appointment_slot.staff_count
            appt_restrict.set_staff_count(appointment_slot.staff_count)
          end
        	api_restricts << Appointment::AppointmentDietRestriction.new(appt_restrict.staff_count, appt_restrict, self, true)
        end
      end
    end
    rescue => error
    	Rollbar.error(error)
    end
    api_restricts
  end

  def serializable_hash(options)
  		if !options.present?
  			options = Hash.new()
  		end
		if options[:methods].present?
			options[:methods] << "rep_confirmed"
			options[:methods] << "office_confirmed"
		else
			options[:methods] = ["rep_confirmed","office_confirmed"]
		end
		if options[:except].present?
			options[:except] << "recommended_cuisines"
		else
			options[:except] = ["recommended_cuisines"]
		end
		super
  end

  # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [])
    params = {}

    scope_strings.each do |scope|
      case scope
        when "active"
          params["status"] = "active"
          params["appointment_on"] = {operator: "gteq", condition: Time.zone.now - 1.day}
        when "past"
          params["status"] = ["active","completed"]
          params["appointment_on"] = {operator: "lteq", condition: Time.zone.now - 1.day}
        when "inactive"
          params["status"] = "inactive"
        # when "recent"
        #   params["status"] = "inactive"
        #   params["created_at"] = {"operator" => "gt", "condition" => Time.now - 30.days }
      end
    end

    params
  end
  # --

  def self.__columns
    cols = {description: 'Description', office_name: 'Office Name', office_location: 'Office Location', sales_rep_name: 'Sales Rep', company_name: 'Company', appointment_date: 'Appointment', organizer_name: 'Sales Rep', slot_type: 'Appointment Type', food_column: 'Food'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
