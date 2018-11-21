class SalesRep < ApplicationRecord
  include LunchproRecord
  mount_uploader :profile_image, Managers::ImageUploaderManager

  attr_accessor :email_address, :phone_number, :for
  attr_accessor :business_email_address, :personal_email_address
  belongs_to :created_by, class_name: 'User'
  belongs_to :company



  has_many :sales_rep_phones, dependent: :destroy
  has_many :sales_rep_emails, dependent: :destroy

  has_many :drugs_sales_reps, dependent: :destroy
  has_many :drugs, through: :drugs_sales_reps

  has_many :offices_sales_reps, dependent: :destroy
  has_many :offices, through: :offices_sales_reps

  has_many :sales_rep_partners, -> { where.not(status: ["deleted"]) }, class_name: 'SalesRepPartner'
  has_many :partners, through: :sales_rep_partners

  has_many :appointments, -> { where.not(status: ["deleted"]) }, dependent: :destroy

  has_many :orders, -> { where.not(status: ["deleted"]) }, dependent: :destroy
  belongs_to :user
  has_many :payment_methods, through: :user

  has_many :order_reviews, as: :reviewer, dependent: :destroy
  accepts_nested_attributes_for :offices_sales_reps
  accepts_nested_attributes_for :sales_rep_emails, :sales_rep_phones
  accepts_nested_attributes_for :user
  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    unless first_name.present?
      self.errors.add(:base, "First name is required")
    end

    if !timezone.present?
      self.timezone = Constants::DEFAULT_TIMEZONE
    end

    if state.present?
      self.errors.add(:base, "Please enter a two character state abbreviation") if state.length != 2
      self.errors.add(:base, "Please enter a valid state abbreviation") if !states.include?(state.upcase)
      self.state = state.upcase
    end

    return self.errors.count == 0
  end

  def update_validations
    create_validations
  end

  def is_lp?
    user.present?
  end

  def upcoming_appointments
    appointments.select{|appt| appt.upcoming? && appt.active?}
  end

  def past_appointments
    appointments.select{|appt| appt.past? }
  end

#--- used to bypass user requirement in notification system
  
  def notifications
    
    if user && !user.new_record?
      user.notifications.order("notified_at desc")
    else      
      Notification.where(:user_id => nil).select{|notif| notif.related_objects["non_lp_sales_rep_id"] && 
        notif.related_objects["non_lp_sales_rep_id"] == id}.sort_by{|notif| notif.notified_at || Time.now}.reverse
    end
  end

  def notification_recipient_type
    "sales_rep"
  end

  def entity
    self
  end

#-----------------

  # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [])
    params = {}

    scope_strings.each do |scope|
      case scope
        when "active"
          params["status"] = "active"
        when "inactive"
          params["status"] = "inactive"
        when "recent"
          params["status"] = "inactive"
          params["created_at"] = {"operator" => "gt", "condition" => Time.now - 30.days }
      end
    end

    params
  end
  # --

  #prevent input of decimal input. if decimal is provider, take floor and save. 2.7 becomes 2
  def default_tip_percent=(tip)
    tip ||= 0
    tip = (tip.to_f / 100).to_f
    write_attribute(:default_tip_percent, (tip.floor * 100))
  end

  def notices
    @notices ||= Views::Notices.for_sales_rep(self).all
  end

  def notification_preferences
    return @preferences if @preferences

    @preferences = []
    NotificationEvent.active.each do |ne|
      if ne.notification_event_recipients.where(recipient_type: 'sales_rep').count > 0
        @preferences << Views::NotificationPreference.new(ne, self.user)
      end
    end

    @preferences
  end

  def determine_notification_trigger_url(event, related_objects)
    return '#' if !related_objects
    trigger_obj = {trigger_url: '#', modal: false, modal_size: nil}
    case event.category_cid.to_i
      when 102
        trigger_obj[:trigger_url] = UrlHelpers.policies_rep_appointments_path(office_id: related_objects[:office_id])
      when 103
        trigger_obj[:trigger_url] = UrlHelpers.rep_appointment_path(related_objects[:appointment_id], is_modal: true)
        trigger_obj[:modal] = true
      when 104
        trigger_obj[:trigger_url] = UrlHelpers.rep_appointment_path(related_objects[:appointment_id], is_modal: true, order_id: related_objects[:order_id])
        trigger_obj[:modal] = true
      when 105
        trigger_obj[:trigger_url] = UrlHelpers.rep_appointment_path(related_objects[:appointment_id], is_modal: true)
        trigger_obj[:modal] = true
      when 106
        trigger_obj[:trigger_url] = UrlHelpers.rep_appointment_path(related_objects[:appointment_id], is_modal: true)
        trigger_obj[:modal] = true
      when 109
        trigger_obj[:trigger_url] = UrlHelpers.rep_appointment_path(related_objects[:appointment_id], is_modal: true, standby: true)
        trigger_obj[:modal] = true
      when 110
        trigger_obj[:trigger_url] = UrlHelpers.show_sample_rep_appointment_path(related_objects[:appointment_id], is_modal: true, require_appointment: true)
        trigger_obj[:modal] = true
      when 111
        trigger_obj[:trigger_url] = UrlHelpers.show_sample_rep_appointment_path(related_objects[:appointment_id], is_modal: true)
        trigger_obj[:modal] = true
      when 113
        trigger_obj[:trigger_url] = UrlHelpers.rep_appointment_path(related_objects[:appointment_id], is_modal: true)
        trigger_obj[:modal] = true
      when 114
        trigger_obj[:trigger_url] = UrlHelpers.policies_rep_appointments_path(office_id: related_objects[:office_id])
      when 116
        trigger_obj[:trigger_url] = UrlHelpers.rep_order_path(related_objects[:order_id])
        trigger_obj[:modal] = true
      when 213
        trigger_obj[:trigger_url] = UrlHelpers.partner_request_rep_profile_partners_path(partner_id: related_objects[:sales_rep_partner_id])
        trigger_obj[:modal] = true
        trigger_obj[:modal_size] = 'sm'
      when 415
        trigger_obj[:trigger_url] = UrlHelpers.rep_appointment_path(related_objects[:appointment_id], is_modal: true)
        trigger_obj[:modal] = true
    end

    trigger_obj
  end

  # -- Appointments

  #checks for duplicate appts and returns the duplicates
  def check_for_duplicate_appointments(appts = [], in_time_zone = false)
    return [] if !appts.any?
    appts.select{|appt| appt.is_duplicate?(in_time_zone)}
  end

  def recent_pending_appointments
    appointments.where(created_at: (Time.now - 6.hours..Time.now), :status => 'pending')
  end


  def next_weeks_appointments(include_non_lp = false)
    date = Date.today + 1.week
    date_range = date.beginning_of_week..date.end_of_week
    if include_non_lp
    else
      appointments.select{|appt| appt.active? && date_range.include?(appt.appointment_on)}.sort_by{|appt| appt.appointment_time(true)}
    end
  end
  # --

  def listed_type(office = nil)
    return 'none' if !office
    type = 'none'
    offices_sales_rep = offices_sales_reps.where(:status => 'active', :office_id => office.id).first
    type = offices_sales_rep.listed_type if offices_sales_rep

    type

  end


  def formatted_specialties
    specialties.join(", ")
  end

  def display_name
    (first_name || last_name) ? "#{first_name} #{last_name}" : email
  end

  def display_location
    self.address_line2.blank? ? "#{self.address_line1}<br/>#{self.display_city_state_postal}".html_safe : "#{self.address_line1}, #{self.address_line2}, #{self.display_city_state_postal}".html_safe
  end

  def display_location_single
    self.address_line2.blank? ? "#{self.address_line1}, #{self.display_city_state_postal}".html_safe : "#{self.address_line1}, #{self.address_line2}, #{self.display_city_state_postal}".html_safe
  end

  def display_city_state_postal
    "#{self.city}, #{self.state} #{self.postal_code}"
  end

  def display_reward_date
    self.last_reward_date.present? ? self.last_reward_date.strftime("%B %e, %Y"): 'No rewards yet'
  end

  def company_name
    if company
      company.name
    else
      "No Company"
    end
  end

  #used in admin table
  def personal_email
    email('personal', false)
  end

  def email(type = nil, message = true)
    if type
      email_record = sales_rep_emails.where(:status => 'active', :email_type => type).first
      if message
        email_record ? email_record.email_address : "Email unavailable"
      else
         email_record ? email_record.email_address : nil
      end
    else
      email_record = sales_rep_emails.select{ |email| email.status == 'active' && email.email_type == 'business' }.first
      if message
        email_record ? email_record.email_address : "Email unavailable"
      else
         email_record ? email_record.email_address : nil
      end
    end
  end

  def email_no_message(type = nil)
    if type
      email_record = sales_rep_emails.where(:status => 'active', :email_type => type).first
      email_record ? email_record.email_address : nil
    else
      email_record = sales_rep_emails.where(:status => 'active', :email_type => 'business').first
      email_record ? email_record.email_address : nil
    end
  end

  def phone_record(type = 'business')
    phone = sales_rep_phones.where(:status => 'active', :phone_type => type).first
    phone.phone_number if phone
  end

  def email_exists?(type = nil)
    sales_rep_emails.where(:status => 'active', :email_type => type).any?
  end

  def phone_exists?(type = nil)
    sales_rep_phones.where(:status => 'active', :phone_type => type).any?
  end

  def phone_single
    phone = sales_rep_phones.select{|phone| phone.phone_type == 'business'}.first
    phone ? phone.phone_number : "Phone unavailable"
  end

  def phone
    sales_rep_phones.select{|phone| phone.phone_type == 'business'}.first
  end

  def user_primary_phone
    to_return = nil
    if user.present?
      to_return = user.primary_phone
    end
    return to_return
  end

  def sales_rep_phone
    to_return = nil
    to_return_obj = phone
    if to_return_obj.present?
      to_return = to_return_obj.phone_number
    end
    return to_return
  end

  def sales_rep_email
    return email
  end

  def drugs
    drugs_sales_reps.active
  end

  def active_offices
    office_ids = []
    offices_sales_reps.select{|osr| osr.active? && osr.listed_type != 1}.each do |office|
      return if !office.office
      if office.office.activated?
        office_ids << office.office.id
      end
    end
    offices = Office.where(id: office_ids)
    offices

  end

  def csv_active_offices
    offices_sales_reps.select{|osr| osr.active? && osr.listed_type != 1 && osr.office.activated?}
  end

  def self.match_email_phone_name(email_address, phone, first_name, last_name)
    sales_reps = SalesRep.includes(:sales_rep_emails,:user,:sales_rep_phones).active.references(:sales_rep_emails, :user,:sales_rep_phones)
    sales_reps = sales_reps.select{ |sales_rep|
      matches = 0

      if email_address.present?
        if sales_rep.sales_rep_emails.present? && sales_rep.sales_rep_emails.any?{ |sales_rep_email| sales_rep_email.active? && sales_rep_email.email_address.present? && sales_rep_email.email_address.downcase == email_address.downcase }
          matches = matches + 1
        elsif sales_rep.user.present? && sales_rep.user.email.present? && sales_rep.user.email.downcase == email_address.downcase
          matches = matches + 1
        end
      end

      if phone.present?
        if sales_rep.user.present? && sales_rep.user.active? && sales_rep.user.primary_phone.present? && sales_rep.user.primary_phone.tr("^0-9", '') == phone.tr("^0-9", '')
          matches = matches + 1
        elsif sales_rep.sales_rep_phones.present? && sales_rep.sales_rep_phones.any?{ |sales_rep_phone| sales_rep_phone.active? && sales_rep_phone.phone_number.present? && sales_rep_phone.phone_number.tr("^0-9", '') == phone.tr("^0-9", '') }
          matches = matches + 1
        end
      end

      if first_name.present? && (sales_rep.first_name.present? && sales_rep.first_name.downcase == first_name.downcase) || (sales_rep.user.present? && sales_rep.user.first_name.present? && sales_rep.user.first_name.downcase == first_name.downcase)
        matches = matches + 1
      elsif last_name.present? && (sales_rep.last_name.present? && sales_rep.last_name.downcase == last_name.downcase) || (sales_rep.user.present? && sales_rep.user.last_name.present? && sales_rep.user.last_name.downcase == last_name.downcase)
        matches = matches + 1
      end

      matches >= 2
    }
    return sales_reps.to_a
  end

  #used in repoffices lists, grabs rep's offices' providers
  def providers
    provider_ids = []
    active_offices.each do |office|
      ids = office.providers.active.pluck(:id)
      provider_ids += ids if ids.count > 0
    end
    providers = Provider.where(id: provider_ids)
    providers
  end

  def appointments_for_orders
    #get active appointments
    appts = appointments.active.where.not(:appointment_slot_id => nil).where(food_ordered: [nil, false]).order(:appointment_on)
    #initialize empty slot, slots array, slot_date
    slots = []
    slot = OpenStruct.new({date: nil, appointments: []})
    slot_date = nil
    appts.each_with_index do |appt, index|
      next if appt.office && !appt.office.activated?
      #if there are no orders for this appt
      if appt.orders.count == 0
        #set slot_date to appts date, set slot object date
        slot_date = appt.appointment_on if !slot_date
        slot.date = slot_date if !slot.date

        #if slot_date is set and current appt is different from previous appointment, push slot into slots array, reset slot_date and slot object
        if slot_date && appt.appointment_on != slot_date
          slot_date = appt.appointment_on
          slots << slot.dup
          slot.date = slot_date
          slot.appointments = []
          slot.appointments.push(appt)

        #if date is the same, push to appointments array of slot object
        elsif slot_date && appt.appointment_on == slot_date
          slot.appointments.push(appt)
        end
        #last iteration, push slot into array
        if index == appts.count - 1
          slots << slot.dup
        end

      end
    end
    slots
  end

  def login_email
    if user
      user.email
    else
      "No Login"
    end
  end

  def is_activated?
    self.activated_at != nil
  end

# HAS TO BE A LP REP
# Used for analytics, active rep user is a user that has booked or cancelled an appointment or ordered food in the last 30 days
  def is_active_user?
    if self.user
      if orders.select{|order| order.created_by_user_id == user_id && (30.days.ago..Time.now).cover?(order.created_at)}.count > 0
        return true
      end
      if appointments.select{|a| (a.created_by_user_id && a.created_by_user_id == user_id && 
        (30.days.ago..Time.now).cover?(a.created_at)) || (a.cancelled_by_id && a.cancelled_by_id == user_id &&
        (30.days.ago..Time.now).cover?(a.cancelled_at))}.count > 0
        return true
      end
      return false
    else
      false
    end
  end

  def full_name
    (first_name || '') + ' ' + (last_name || '')
  end

  def past_orders
    orders.select{|o| ['active', 'completed'].include?(o.status) && o.appointment && o.appointment.past?}
  end

  #used in order history to grab list of appointments that meet criteria of order.appointment to be reordered
  def upcoming_appointments_for_reorder(appointment)
    return nil if !appointment || !appointment.restaurant_id || !appointment.appointment_slot
    appointments.select{|appt| appt.active? &&
      !appt.food_ordered &&
      appt.appointment_slot &&
      appt.appointment_slot.slot_type == appointment.appointment_slot.slot_type &&
      appt.starts_at == appointment.starts_at && appt.ends_at == appointment.ends_at &&
      appt.appointment_time(true) > Time.now.in_time_zone(appt.office.timezone) &&
      !appt.office.least_favorite_restaurants_ids.split(',').include?(appointment.restaurant_id.to_s) &&
      !appointment.restaurant.restaurant_exclude_dates.where("starts_at <= ? and ends_at >= ?", appt.appointment_on, appt.appointment_on).any? &&
      appointment.restaurant.restaurant_availabilities.exists? &&
      appointment.restaurant.restaurant_availabilities.select{|avail| avail.active? && avail.day_of_week.to_i == appt.appointment_on.wday.to_i &&
        Tod::Shift.new(avail.starts_at, avail.ends_at).include?(Tod::TimeOfDay(appt.starts_at))}.any?
    }.sort_by{|appt| appt.appointment_time(true)}
  end

  def recent_past_appointment(office, appointment)
    return nil if !appointment.appointment_slot
    office.appointments.select{|appt|
      appt.sales_rep_id == self.id &&
      ['active', 'completed'].include?(appt.status) &&
      appt.orders.select{|order| ['active', 'completed'].include?(order.status)}.any? &&
      appt.appointment_slot &&
      appt.appointment_slot.slot_type == appointment.appointment_slot.slot_type &&
      appt.starts_at == appointment.starts_at && appt.ends_at == appointment.ends_at &&
      appt.appointment_time(true) < Time.now.in_time_zone(office.timezone) &&
      (!appt.restaurant.present? ||
      !appt.restaurant.restaurant_exclude_dates.where("starts_at <= ? and ends_at >= ?", appointment.appointment_on, appointment.appointment_on).exists?) &&
      appt.restaurant.restaurant_availabilities.exists? &&
      appt.restaurant.restaurant_availabilities.select{|avail| avail.active? && avail.day_of_week.to_i == appointment.appointment_on.wday.to_i &&
        Tod::Shift.new(avail.starts_at, avail.ends_at).include?(Tod::TimeOfDay(appointment.starts_at))}.any?
    }.sort_by{|appt| appt.appointment_time(true)}.reverse!.first
  end

  def recent_past_order(office, appointment)
    return nil if !office || !appointment || !appointment.appointment_slot
    appt = recent_past_appointment(office, appointment)
    if appt
      appt.orders.first
    else
      nil
    end
  end

  def recent_past_order_non_lp(office, appointment)
    appt = appointments.select{|appt| appt.office_id == office.id &&
      appt.active? &&
      appt.orders.select{|order| ['active', 'completed'].include?(order.status)}.any? &&
      appt.appointment_time(true) < Time.now.in_time_zone(office.timezone)
    }.sort_by{|appt| appt.appointment_time(true)}.reverse!.first

    return nil if !appt
    appt.orders.select{|order| ['active', 'completed'].include?(order.status)}.first
  end

  def recent_past_order_review
    order = recent_past_order
    if order
      order.order_reviews.where(:reviewer_id => id, :reviewer_type => "SalesRep").first
    else
      nil
    end
  end

  def eligible_partners_selectize
    eligible_partners = []
    partners = SalesRep.select(:id, :first_name, :last_name, :company_id).where(:status => "active").where.not(id: ineligible_partners_ids, company_id: nil)
    partners.each do |partner|
      eligible_partners << {id: partner.id, name: partner.first_name + ' ' + partner.last_name, company: partner.company.name}
    end
    eligible_partners.to_json
  end

  def eligible_partners
    return SalesRep.where(:status => "active").where.not(id: ineligible_partners_ids, company_id: nil)
  end

  def pending_partners
    SalesRepPartner.where(:status => "pending", :partner_id => id)
  end

  def non_lp
    return !user.present? || (!user.confirmed_at.present? && !user.invitation_accepted_at.present?)
  end

  def self.__columns
    cols = {display_name: 'Name', display_location_single: 'Location', display_location: 'Location',
      company_name: 'Company', login_email: 'Login Email', display_reward_date: 'Last Reward Date',
      is_lp?: 'Lunchpro Rep', phone_record: 'Phone', email_no_message: 'Email'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

  def serializable_hash(options)
      if !options.present?
        options = Hash.new()
      end
    if options[:methods].present?
      options[:methods] << "user_primary_phone"
      options[:methods] << "sales_rep_phone"
      options[:methods] << "sales_rep_email"
      options[:methods] << "non_lp"
    else
      options[:methods] = ["user_primary_phone","sales_rep_phone","sales_rep_email","non_lp"]
    end
    to_return = super

    profile_image_url = nil
    if profile_image.present?
      profile_image_url = profile_image.url
    end

    to_return["profile_image"] = profile_image_url

    to_return
  end


  private
  def ineligible_partners_ids
      partner_ids = self.sales_rep_partners.where(status:["pending", "accepted"]).pluck(:partner_id)
      partner_ids << self.id
      partner_ids += SalesRepPartner.where(:status => 'rejected', :sales_rep_id => id).pluck(:partner_id)
      return partner_ids
  end
end
