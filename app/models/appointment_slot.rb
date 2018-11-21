class AppointmentSlot < ApplicationRecord
	include LunchproRecord
  attr_accessor :_destroy
  before_save :convert_times_to_utc, :set_timestamps
  #after_update :update_appointments
	serialize :starts_at, Tod::TimeOfDay
	serialize :ends_at, Tod::TimeOfDay

	belongs_to :office
	has_many :appointments, dependent: :destroy # Appointments that fill this slot on various weeks


	validate :create_validations, :on => :create
	validate :update_validations, :on => :update


	enum day_of_week: {
		monday: Constants::DOW_MONDAY,
		tuesday: Constants::DOW_TUESDAY,
		wednesday: Constants::DOW_WEDNESDAY,
		thursday: Constants::DOW_THURSDAY,
		friday: Constants::DOW_FRIDAY,
		saturday: Constants::DOW_SATURDAY,
		sunday: Constants::DOW_SUNDAY
	}

  enum slot_type: {
    breakfast: Constants::SLOT_BREAKFAST,
    lunch: Constants::SLOT_LUNCH,
    dinner: Constants::SLOT_DINNER,
    snack: Constants::SLOT_SNACK,
    sample: Constants::SLOT_SAMPLE
  }
  before_save :flag_for_notifications
  after_save :trigger_notifications

  def flag_for_notifications
    @notify_staff_count_changed = false
    if self.staff_count_changed?
      @notify_staff_count_changed = true
    end
    if self.status_changed? && self.status == 'inactive' && future_appointments(true).any?
      @notify_appointment_cancel = true
    end
  end

  def trigger_notifications
    begin
      if @notify_staff_count_changed
        future_appointments.each do |appt|
          Managers::NotificationManager.trigger_notifications([113], [office, appt, appt.sales_rep], {staff_count_changed: true})
        end        
      elsif @notify_appointment_cancel
        future_appointments(true).each do |appt|
          order = appt.active_order        
          if order
            # Trigger Notification 104 - Office: Cancels appointment WITH attached order
            Managers::NotificationManager.trigger_notifications([104], [appt, appt.office, appt.sales_rep, 
              appt.appointment_slot, order])
          else
            # Trigger Notification 103 - Office: Cancels appointment WITHOUT attached order
            Managers::NotificationManager.trigger_notifications([103], [appt, appt.office, appt.sales_rep, 
              appt.appointment_slot])
          end
          appt.update(:cancelled_at => Time.now, :cancelled_by_id => self.deactivated_by_id, :status => 'inactive')
          appt.orders.each do |order|
            order.update(:status => 'inactive')
          end         
        end
      end
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end
  # -- End notification trigger callbacks
	# LWH FIXME
	# validate the uniqueness of the slot scoped to the office.. might need to break slots into 15min increments (and truncate to the minutes marker)
	# validate that a slot doesn't overlap.. same thoughts here ^ apply

  def set_timestamps
    if !self.new_record?
      if self.status_changed? && self.status == 'inactive'
        self.deactivated_at = Time.now
      end
    else
      if self.active?
        self.deactivated_by_id = nil
        self.activated_at = Time.now
      end
    end
  end

  def convert_times_to_utc
    return if !self.starts_at.present? || !self.ends_at.present?
    self.starts_at = Managers::TimeManager.new(self.starts_at, nil, office_id).time_converted_to_utc if self.starts_at_changed?
    self.ends_at = Managers::TimeManager.new(self.ends_at, nil, office_id).time_converted_to_utc if self.ends_at_changed?
  end

  def self.day_of_week_non_iso(day)
    return 7 if day == "sunday"

    self.day_of_weeks[day]
  end

	def create_validations
    if status == 'active' && !_destroy
      unless office_id.present?
        self.errors.add(:base, "You must provide an office id.")
      end
      if slot_type.present?
        self.name = slot_type.capitalize
      else
        self.errors.add(:base, "You must provide a slot type.")
        office.errors.add(:base, "You must provide a slot type.")
      end
  		unless name.present?
  			self.errors.add(:base, "You must specify a name for your appointment slot")
  		end

  		unless starts_at && ends_at
  			self.errors.add(:base, "You must assign a starting and ending time for the slot")
        office.errors.add(:base, "You must assign a starting and ending time for the slot.")
  		end
  		if starts_at && ends_at
        if (check_time_changes || self.day_of_week_changed?) && future_appointments.any?  
          self.errors.add(:base, "You cannot update this timeslot when there are upcoming appointments for this slot.")  
          office.errors.add(:base, "You cannot update this timeslot when there are upcoming appointments for this slot.")
        end
        unless validate_uniqueness
          self.errors.add(:base, "You cannot create a duplicate appointment slot.")
          office.errors.add(:base, "You cannot create a duplicate appointment slot.")
        end
  			unless starts_at <= ends_at
  				self.errors.add(:base, "The start time must be earlier than the end time for the slot")
          office.errors.add(:base, "The start time must be earlier than the end time for the slot")
  			end
  		end
    end

    if status == 'inactive' && appointments.select{|appt| appt.active? && appt.active_order && !appt.active_order.cancellable? }.any?
      self.errors.add(:base, "The #{self.day_of_week.humanize}: #{self.name} appointment slot cannot be deleted, there are outstanding orders. Please contact LunchPro for more assistance.")
      office.errors.add(:base, "The #{self.day_of_week.humanize}: #{self.name} appointment slot cannot be deleted, there are outstanding orders. Please contact LunchPro for more assistance.")
    end

		return self.errors.count == 0
	end

  def update_validations
    create_validations
  end

  def calendar_key
    case slot_type
    when "breakfast"
      "BR"
    when "lunch"
      "LU"
    when "snack"
      "SN"
    when "sample"
      "RX"
    when "dinner"
      "DN"
    end

  end

  def self.formatted_day_of_weeks
    LunchproRecord::formatted_day_of_weeks
  end

  def starts_at(local = false)
    #default pass back as utc
    #or use office timezone or local timezone and convert time to datetime object with offset of timezone
    if local
      timezone = office.timezone || Time.zone.name
      converted_time = (starts_at.on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone) 
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
      converted_time = (ends_at.on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone) 
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:ends_at)
    end
  end

  def update_appointments
    if self.status == 'active'
      appointments.where("appointment_on > ?", Time.now.to_s).update(:starts_at => starts_at, :ends_at => ends_at)
    else      
      appointments.where("appointment_on > ?", Time.now.to_s).update(:status => 'inactive', :cancelled_at => Time.now, :cancelled_by_id => self.deactivated_by_id)
    end
  end

	def self.by_time
		order({starts_at: :asc})
	end

  def future_appointments(include_internal = false)
    if include_internal
      appointments.select{|appt| appt.active? && appt.appointment_time(true) > Time.now.in_time_zone(appt.office.timezone)}
    else
      appointments.select{|appt| appt.active? && appt.sales_rep_id.present? && appt.appointment_time(true) > Time.now.in_time_zone(appt.office.timezone)}
    end
  end

  def slot_time(in_zone = false, date = Time.now.to_date)
    # A combination of the slot and date
    return nil if !date.present?
    if in_zone
      time = starts_at(true)
    else
      time = starts_at
    end
    date = time.on date
  end

	def reserved?(date)
		Appointment.where(appointment_slot_id: self.id, appointment_on: date).where.not(status: ['inactive', 'deleted']).count > 0
	end

  def total_staff_count(providers = [], date = nil)

    staff_count + office.providers_available_at(self, false, providers, date).count
  end

  private

    def convert_time_to_local(time)
      timezone = office.timezone || Time.zone.name
      converted_time = (time.on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone) 
      Tod::TimeOfDay(converted_time.to_s(:time))
    end

    def check_time_changes
      return false if self.new_record?
      starts_was = convert_time_to_local(starts_at_was)
      ends_was = convert_time_to_local(ends_at_was)
      if (starts_was != starts_at) || (ends_was != ends_at)
        true
      else
        false
      end
    end
    def validate_uniqueness
      !office.appointment_slots.all.select{|slot| slot.slot_type == slot_type && slot.status == 'active' && slot.id != id && 
        slot.day_of_week == day_of_week && [slot.starts_at, slot.starts_at(true)].include?(starts_at) && 
        [slot.ends_at, slot.ends_at(true)].include?(ends_at)}.any?
      
      #!(office.appointment_slots.where(starts_at: starts_at, ends_at: ends_at, :slot_type => slot_type, :day_of_week => day_of_week, :status => 'active').where.not(id: self.id).exists? ||
       # office.appointment_slots.where(starts_at: starts_at(true), ends_at: ends_at(true), :slot_type => slot_type, :day_of_week => day_of_week, :status => 'active').where.not(id: self.id).exists?)
    end

end
