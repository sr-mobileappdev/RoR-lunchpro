class Office < ApplicationRecord
  include LunchproRecord
  attr_accessor :edit_diet_restrictions_offices
  attr_accessor :poc_phone
  attr_accessor :passcode_status
  # Custom attributes for certain notification circumstances
  attr_accessor :notify_open_calendar
  belongs_to :creating_sales_rep, class_name: 'SalesRep'
  belongs_to :created_by, class_name: 'User'

	has_and_belongs_to_many :providers
	has_and_belongs_to_many :holiday_exclusions

	has_many :office_exclude_dates, dependent: :destroy
	has_many :office_pocs, dependent: :destroy

	has_many :offices_sales_reps, dependent: :destroy
	has_many :sales_reps, through: :offices_sales_reps

  has_many :user_offices, dependent: :destroy
  has_many :users, through: :user_offices

  has_many :offices_providers
  has_many :providers, through: :offices_providers, dependent: :destroy

  has_many :diet_restrictions_offices, dependent: :destroy
  has_many :diet_restrictions, through: :diet_restrictions_offices

	has_many :office_restaurant_exclusions, dependent: :destroy
	has_many :blocks, through: :office_restaurant_exclusions
	has_many :restaurant_exclusions, through: :office_restaurant_exclusions

  has_many :appointments, -> { where.not(status: ["deleted"]) }, dependent: :destroy
  has_many :appointment_slots, dependent: :destroy

  has_many :order_reviews, as: :reviewer, dependent: :destroy
  has_many :office_referrals

  has_many :office_device_logs

  accepts_nested_attributes_for :diet_restrictions_offices
  accepts_nested_attributes_for :office_exclude_dates, allow_destroy: true
  accepts_nested_attributes_for :office_pocs, :offices_sales_reps
  accepts_nested_attributes_for :diet_restrictions_offices, allow_destroy: true
  accepts_nested_attributes_for :office_restaurant_exclusions, allow_destroy: true
  accepts_nested_attributes_for :appointment_slots, allow_destroy: true

  geocoded_by :geocodable_street_address   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  before_save :update_policies_timestamp

  # Before and after save trigger for notifications related to changing elements, such as office calendar opening up more dates
  before_save :flag_for_notifications
  after_save :trigger_notifications
  after_create :set_holidays

  def flag_for_notifications
    @notify_open_calendar = false
    @active_slot_ids = self.appointment_slots.active.pluck(:id)
    if !self.new_record? && self.activated? && self.appointments_until_changed? &&
      ((self.appointments_until_was.present? && (self.appointments_until_was < self.appointments_until)) ||
        !self.appointments_until_was.present?)
      @notify_open_calendar = true
    end
  end

  def trigger_notifications
    begin
      if @notify_open_calendar
        Managers::NotificationManager.trigger_notifications([102], [self], {related_sales_reps: active_reps(true, true)})
      elsif (self.appointment_slots.active.pluck(:id) -  @active_slot_ids).any? && self.activated?
        Managers::NotificationManager.trigger_notifications([114], [self], {related_sales_reps: active_reps(true, true)})
      end
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end
  # -- End notification trigger callbacks

  #Beforelaunch: temp solution for setting default fedaral holidays
  def set_holidays
    if internal
      HolidayExclusion.active.each do |hol|
        office_exclude_dates << OfficeExcludeDate.new(:starts_at => hol.starts_on, :ends_at => hol.ends_on)
      end
    end
  end

#--- Manager or POC info

  def manager
    users.select{|u| u.active?}.first
  end

  def manager_name
    return nil if !manager
    manager.display_name
  end

  def manager_email
    return nil if !manager
    manager.email
  end

  def manager_phone
    return nil if !manager
    ApplicationController.helpers.format_phone_number_string(manager.try(:phone) || manager.try(:primary_phone))
  end

#----


  def create_validations
    unless name.present?
      self.errors.add(:base, "Office name is required")
    end
    unless timezone.present?
      self.errors.add(:base, "Timezone is required")
    end
    unless address_line1.present? && city.present? && state.present? && postal_code.present?
      self.errors.add(:base, "Address is required")
    end

    unless phone.present?
      self.errors.add(:base, "Phone is required")
    end
    if Office.select{|office| office.name.downcase == name.downcase && office.active? && office.internal && office.id != id}.any?
      self.errors.add(:base, "An office with this name already exists.")
    end
    if address_line2.present?
      if Office.select{|office| office.active? && office.internal && office.address_line1.downcase == address_line1.downcase &&
        office.address_line2.downcase == address_line2 && office.postal_code == postal_code && office.id != id}.any?
         self.errors.add(:base, "An office already exists at this address.")
      end

    else
      if Office.select{|office| office.active? && office.internal && office.address_line1.downcase == address_line1.downcase &&
        office.postal_code == postal_code && office.id != id}.any?
         self.errors.add(:base, "An office already exists at this address.")
      end

    end
    if appointments_until.present?
      if appointments.select{|appt| appt.active? && appt.appointment_on > appointments_until}.any?
        self.errors.add(:base, "You must cancel all appointments set for after this date before saving.")
      end
    end

    if state.present?
      self.errors.add(:base, "Please enter a two character state abbreviation") if state.length != 2
      self.errors.add(:base, "Please enter a valid state abbreviation") if !states.include?(state.upcase)
      self.state = state.upcase
    end

    if !total_staff_count.present? && private__flag
      self.errors.add(:base, "Staff count is required.")
    end
    
    return self.errors.count == 0
  end


  def update_validations
    if status != 'inactive'
      create_validations
    end
  end


  def appointments_in_range(days = nil)
    return [] if !days
    if days == '90+'
      appointments.select{|appt| appt.active? && appt.appointment_on > (Time.now.to_date + 90.days)}
    elsif days.kind_of?(Integer)
      range = Time.now.to_date..(Time.now.to_date + days.days)
      appointments.select{|appt| appt.active? && range.cover?(appt.appointment_on)}
    end
  end

  def future_appointments(active = true)
    if active
      appointments.select{|appt| appt.active? && appt.upcoming?}
    else
      appointments.select{|appt| appt.upcoming? && !appt.draft? && !appt.cancelled?}
    end
  end

  def past_appointments
    Appointment.past.select{|appt| appt.office_id == id}
  end

  def visiting_reps_count
    appointments.select{|appt| appt.completed?}.pluck(:sales_rep_id).uniq.count
  end

  def update_policies_timestamp
    self.policies_last_updated_at = Time.zone.now if self.office_policy_changed? || self.food_preferences_changed?
  end
  # --

  def has_policies?
    self.office_policy.present? && self.food_preferences.present? && self.delivery_instructions.present?
  end

  def can_activate?
    activation_notices.count == 0
  end

  def passcode_active?
    self.passcode.present? && self.passcode_active
  end

  def notices
    @notices ||= Views::Notices.for_office(self).all
  end

  def activation_notices
    @activation_notices ||= Views::Notices.for_office(self).activation
  end

  def activated?
    self.status == 'active' && self.activated_at.present?
  end

  def is_active?
    self.activated_at.present? && !self.deactivated_at.present?
  end

  def deactivated_by
    User.find(deactivated_by_id) if deactivated_by_id
  end
  def primary_phone
    "214-364-0193"
  end

  def display_location
    self.address_line2.blank? ? "#{self.address_line1}<br/>#{self.display_city_state_postal}".html_safe : "#{self.address_line1} #{self.address_line2}, #{self.display_city_state_postal}".html_safe
  end

  def display_location_single
    self.address_line2.blank? ? "#{self.address_line1}, #{self.display_city_state_postal}".html_safe : "#{self.address_line1} #{self.address_line2}, #{self.display_city_state_postal}".html_safe
  end

  def display_city_state_postal
    "#{self.city}"","" #{self.state} #{self.postal_code}"
  end

  def display_location_city
    "#{self.city}"","" #{self.state}"
  end

  def private__flag
    return !internal
  end


  def lunchpad_status__light
    case lunchpad_status      
    when 'active'
      "on"
    when 'stale'
      "stale"
    when 'inactive'
      "off"
    end
  end

  def lunchpad_status
  # logic for whether or not the office's lunchpad is connected
    last_log = office_device_logs.order(:created_at).last
    return 'inactive' if !last_log

    if last_log.created_at >= (Time.now - 1.day)
      return 'active'
    elsif last_log.created_at >= (Time.now - 3.days)
      return 'stale'
    else
      return 'inactive'
    end
  end

  def calendar_open_until
    ApplicationController.helpers.simple_date(self.appointments_until, Date.today, true)
  end

  def calendar_closing_soon?
    (appointments_until == Time.now.to_date + 2.weeks)
  end

  def listed_reps(list_type)
    SalesRep.where(:status => 'active', id: offices_sales_reps.select{|o| o.active? && o.listed_type == list_type}.pluck(:sales_rep_id))
  end
  def creating_sales_rep_name
    (creating_sales_rep) ? creating_sales_rep.display_name : nil
  end

  def active_reps(hide_blacklist = false, check_appts = false)
    #logic to only grab sales reps that aren't blacklisted
    if hide_blacklist
      reps = SalesRep.joins(:offices_sales_reps).where(:status => 'active', offices_sales_reps: {:office_id => self.id, :status => 'active'}).where.not(offices_sales_reps: {:listed_type => 'blacklist'})
      if check_appts
        reps = reps.select{|rep| rep.appointments.where('created_at >= ?', Time.now - 1.year).any?}
      end
    else
      reps = SalesRep.where(id: offices_sales_reps.active.pluck(:sales_rep_id), :status => 'active')
      if check_appts
        reps = reps.select{|rep| rep.appointments.where('created_at >= ?', Time.now - 1.year).any?}
      end      
    end
    reps
  end

  #for notifications, grabs users that are active and arent blacklisted
  def active_users
    User.find(SalesRep.joins(:offices_sales_reps).where(:status => 'active',
      offices_sales_reps: {:office_id => self.id, :status => 'active'}).where.not(offices_sales_reps:
      {:listed_type => 'blacklist'}).pluck(user_id))
  end
  def appointment_slots_by_day
    by_day = {"monday" => [], "tuesday" => [], "wednesday" => [], "thursday" => [], "friday" => [], "saturday" => [], "sunday" => []}
    appointment_slots.select{|s| s.active?}.sort_by{|s| s.starts_at}.each do |s|
      s.starts_at = s.starts_at(true)
      s.ends_at = s.ends_at(true)
      by_day[s.day_of_week] << s
    end

    by_day
  end

  #used for filtered by provider
  #iterate through active slots, check if filtered providers are available for each slot
  def filtered_appointment_slots(providers)
    allSlots = appointment_slots.select(:day_of_week, :id, :starts_at, :ends_at, :office_id, :name, :staff_count).active.to_a
    allSlots = allSlots.select {|slot| (providers & providers_available_at(slot, true, providers)).length == providers.length}

    AppointmentSlot.select(:day_of_week, :id, :starts_at, :ends_at, :office_id, :name, :staff_count).where(id: allSlots.pluck(:id))
  end


  def providers_available_at(appointment_slot, id_only = false, provider_ids = [], date = nil)
    available_providers = []
    provider_ids = provider_ids || []
    providers = self.providers.to_a

    # if specific date is provided, check against provider_exclude_dates
    if date
      providers = providers.select {|pro|
        exclude_dates = pro.provider_exclude_dates.to_a
        exclude_dates.select {|excl|
          !(excl.starts_at.to_date..excl.ends_at.to_date).cover?(date)
        }.length == exclude_dates.length &&
        pro.active? &&
        pro.provider_availabilities.to_a.select {|avail|
          avail.day_of_week == appointment_slot.day_of_week &&
          Tod::Shift.new(avail.starts_at, avail.ends_at).contains?(Tod::Shift.new(Tod::TimeOfDay(appointment_slot.starts_at), Tod::TimeOfDay(appointment_slot.ends_at)))
        }.any?
      }
    else
      providers = providers.select {|pro|
        pro.active? &&
        pro.provider_availabilities.to_a.select {|avail|
          avail.day_of_week == appointment_slot.day_of_week &&
          Tod::Shift.new(avail.starts_at, avail.ends_at).contains?(Tod::Shift.new(Tod::TimeOfDay(appointment_slot.starts_at), Tod::TimeOfDay(appointment_slot.ends_at)))
        }.any?
      }
    end

    if id_only
      available_providers = providers.pluck(:id).map(&:to_s)
    else
      available_providers = providers.to_a
    end

    available_providers.uniq
  end

  # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [])
    params = {}

    scope_strings.each do |scope|
      case scope
        when "active"
          params["status"] = "active"
          params["internal"] = "true"
        when "inactive"
          params["status"] = "inactive"
          #
        when "active internal"
          params["status"] = "active"
          params["internal"] = "false"
          #
        # when "recent"
        #   params["status"] = "inactive"
        #   params["created_at"] = {"operator" => "gt", "condition" => Time.now - 30.days }
      end
    end

    params
  end
  # --
=begin
  def providers_available_at(appointment_slot, id_only = false)
    available_providers = []


    self.providers.active.each do |provider|
      if provider.available_at(appointment_slot)
        if id_only
          available_providers << provider.id.to_s
        else
          available_providers << provider
        end
      else

      end
    end
    available_providers.uniq
  end
=end

  #this gets the raw day_of_week integer used for office manager calendar
  def week_availability
    days = []
    full_days = appointment_slots.active.order(:day_of_week).pluck(:day_of_week).uniq
    full_days.each do |day|
      if day == "sunday"
        days << 0
      else
        days << AppointmentSlot.day_of_weeks[day]
      end
    end
    days
  end

  #loop through slots and create a 'schedule' of start to end time based on slot's start and end time. will be used to set default provider avails
  ## Example: [{day_of_week: 'monday', starts_at: '07:00:00', ends_at: '17:00:00'}, {day_of_week: 3, starts_at: '12:00:00', ends_at: '19:00:00'}]
  def week_schedule
    days = []
    AppointmentSlot.day_of_weeks.each do |value, key|
      slots = appointment_slots.where(:status => 'active', :day_of_week => value).sort_by{|slot| slot.starts_at(true)}
      next if !slots.present?
      days << {day_of_week: value, starts_at: slots.first.starts_at(true), ends_at: slots.sort_by{|slot| slot.ends_at(true)}.reverse.first.ends_at(true)}
    end
    days
  end

  def recent_order(appointment)
    return nil if !appointment.appointment_slot
    appointments.joins(:orders, :appointment_slot)     #only grab appts with orders and an appt slot
    .where("appointments.appointment_on < ? and appointment_slots.slot_type = ?",   #and appts with appt_slot day_of_week is less than, and slot_type is the same
      appointment.appointment_on,
      AppointmentSlot.slot_types[appointment.appointment_slot.slot_type])
    .where(status: ['active', 'completed'], orders: {status: ['active','completed']}).where.not(:restaurant_id => nil).first
  end

  def poc_phone
    office_pocs.active.where(:primary => true).first ? office_pocs.active.where(:primary => true).first.phone : nil
  end

  def office_poc
    office_pocs.active.where(:primary => true).first
  end

  def least_favorite_restaurants_ids
    office_restaurant_exclusions.map(&:restaurant_id).join ','
  end

  def available_restaurants
    #TODO, implement orders_until #
    #(appt.appointment_on - (Restaurant.orders_untils[rest.orders_until] - 1).days) + rest.orders_until_hour.hours
    restaurants = Restaurant.includes(:delivery_distance, :restaurant_availabilities, :cuisines, :restaurant_exclude_dates).includes(orders: [:order_reviews]).find_in_range_to_office(self)
    least_favorite_restaurants = least_favorite_restaurants_ids.split(',')
    restaurants = restaurants.select{|rest| !least_favorite_restaurants.include?(rest.id.to_s) } if restaurants.any?
    restaurants
  end

  #uses available_restaurants to further filter if restaurant has exclusion dates and restaurant avails set
  def filtered_available_restaurants(appointment, current_user, impersonation = false)
    restaurants = []
    return restaurants if !appointment
    #only select available_restaurants that dont have exclusion date ranges that include appointment.appointment_on
    #only select available_restaurants that have availabiltiies set which include an appointment's start time
    if impersonation
      restaurants = Restaurant.includes(menus: [:menu_items]).includes(:cuisines).includes(orders: [:order_reviews]).where("status = 1 and activated_at is not null").select{|rest| 
        rest.menus.select{|menu| menu.active? && menu.menu_items.select{|mi| mi.active?}.any?}.any?}
    else
      restaurants = available_restaurants.select {|r| r.orders_until_date_and_time(appointment) &&
        (Time.now.in_time_zone(appointment.office.timezone) < r.orders_until_date_and_time(appointment)) &&
        !r.restaurant_exclude_dates.select{|r| r.starts_at <= appointment.appointment_on && r.ends_at >= appointment.appointment_on}.any? &&
        r.restaurant_availabilities.to_a.any? &&
        r.restaurant_availabilities.select{|avail| avail.active? && avail.day_of_week.to_i == appointment.appointment_on.wday.to_i &&
          Tod::Shift.new(avail.starts_at, avail.ends_at).include?(Tod::TimeOfDay(appointment.starts_at))}.any? &&
        r.menus.select{|menu| menu.active? && menu.menu_items.active.any? &&
          Tod::Shift.new(menu.start_time, menu.end_time).include?(Tod::TimeOfDay(appointment.starts_at))}.any?
      }
    end

    restaurants
  end

  def self.__columns
    cols = {display_location_single: 'Location', display_location: 'Location', private__flag: 'Is Private?', calendar_open_until: 'Calendar End Date', status__light: 'Status', lunchpad_status: 'LunchPad Connectivity', lunchpad_status__light: 'LunchPad Connectivity'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

  private

  def geocodable_street_address
    [address_line1, city, state, postal_code, country].compact.join(', ')
  end

end
