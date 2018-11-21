class ProviderAvailability < ApplicationRecord
  include LunchproRecord
  attr_accessor :_destroy

  attr_accessor :office_id

  default_scope { order(:starts_at) }
  before_save :convert_times_to_utc
  serialize :starts_at, Tod::TimeOfDay
  serialize :ends_at, Tod::TimeOfDay

	belongs_to :provider
	validates_presence_of :provider

  enum day_of_week: {
    monday: Constants::DOW_MONDAY,
    tuesday: Constants::DOW_TUESDAY,
    wednesday: Constants::DOW_WEDNESDAY,
    thursday: Constants::DOW_THURSDAY,
    friday: Constants::DOW_FRIDAY,
    saturday: Constants::DOW_SATURDAY,
    sunday: Constants::DOW_SUNDAY
  }
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  before_save :flag_for_notifications
  after_save :trigger_notifications

  #ignoring provider exclusion dates for now
  def flag_for_notifications
    if !self.new_record?
      @existing_appointments = provider.office.appointments.select{|appt| appt.active? && appt.sales_rep && appt.appointment_on.present? && 
        appt.appointment_on.wday == Provider.day_of_weeks[self.day_of_week] &&
        Tod::Shift.new(self.starts_at_was, self.ends_at_was).contains?(Tod::Shift.new(Tod::TimeOfDay(appt.starts_at), Tod::TimeOfDay(appt.ends_at)))}
    else
      @new_avail_record = true
    end
  end

  def trigger_notifications
    if status == 'deleted'
      @appointments_to_notify = @existing_appointments
    elsif @new_avail_record
      @appointments_to_notify = provider.office.appointments.select{|appt| appt.active?  && appt.sales_rep && appt.appointment_on.present? && 
        appt.appointment_on.wday == Provider.day_of_weeks[self.day_of_week] &&
        Tod::Shift.new(self.starts_at, self.ends_at).contains?(Tod::Shift.new(Tod::TimeOfDay(appt.starts_at), Tod::TimeOfDay(appt.ends_at)))}
    else
      @new_appointments = provider.office.appointments.select{|appt| appt.active?  && appt.sales_rep && appt.appointment_on.present? && 
        appt.appointment_on.wday == Provider.day_of_weeks[self.day_of_week] &&
        Tod::Shift.new(self.starts_at, self.ends_at).contains?(Tod::Shift.new(Tod::TimeOfDay(appt.starts_at), Tod::TimeOfDay(appt.ends_at)))}
        
      @appointments_to_notify = (@new_appointments - @existing_appointments | @existing_appointments - @new_appointments)
    end

    begin
      @appointments_to_notify.each do |appt|
        Managers::NotificationManager.trigger_notifications([113], [provider.office, appt, appt.sales_rep])
      end        
    rescue Exception => e
      # Trap any unexpected exceptions here, allowing the callback to complete
      Rollbar.error(e)
    end
  end

  def convert_times_to_utc
    return if !self.starts_at.present? || !self.ends_at.present?
    if provider.office
      office_id = provider.office.id
    end
    self.starts_at = Managers::TimeManager.new(self.starts_at, nil, office_id, nil).time_converted_to_utc if self.starts_at_changed?
    self.ends_at = Managers::TimeManager.new(self.ends_at, nil, office_id, nil).time_converted_to_utc if self.ends_at_changed?
  end

  def create_validations
    if status == 'active' && !_destroy
      if ends_at.present? && starts_at.present?
        unless ends_at >= starts_at
          provider.errors.add(:base, "End time must be after start time.")
        end
      else
        provider.errors.add(:base, "You must provide both start and end times")
      end
      validate_overlap
    end   
    return self.errors.count == 0
  end

  def update_validations
    create_validations
  end

  def starts_at(local = false)
    #default pass back as utc
    #or use office timezone or local timezone and convert time to datetime object with offset of timezone
    if local
      timezone = provider.office.timezone || Time.zone.name
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
      timezone = provider.office.timezone || Time.zone.name
      converted_time = (ends_at.on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone) 
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:ends_at)
    end
  end

  def self.by_time
    order({starts_at: :asc})
  end

  private

  def validate_overlap

  end
end
