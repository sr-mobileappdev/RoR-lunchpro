class Templates::Web::AppointmentTemplate < Templates::BaseTemplate
  attr_reader :appointment

  def initialize(obj = nil)
    @object_type = obj.class
    @appointment = obj
  end

  def tags
    return [] if !@appointment
    {
      short_date: 'appointment_short_date',
      name: 'slot_name',
      day_and_time: 'day_and_time'
    }
  end
  
  def __appointment_short_date
    ApplicationController.helpers.short_date(@appointment.appointment_on)
  end

  def __slot_name
    (@appointment.appointment_slot) ? @appointment.appointment_slot.name : 'Unknown'
  end

  def __day_and_time
    ApplicationController.helpers.long_date(@appointment.appointment_time_in_zone)
  end

end
