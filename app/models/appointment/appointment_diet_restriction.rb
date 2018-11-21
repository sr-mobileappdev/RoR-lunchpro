class Appointment::AppointmentDietRestriction
  attr_accessor :staff_count
  attr_reader :diet_restriction
  attr_reader :appointment
  attr_reader :diet_restriction_id

  def initialize(staff_count, diet_restriction, appointment, for_api = false)
    @staff_count = 0
    @diet_restriction_id = nil
    @appointment_id = nil
    @name = nil
    if for_api
      @staff_count = staff_count
      @diet_restriction_id = diet_restriction.id
      @appointment_id = appointment.id
      @name = diet_restriction.diet_restriction ? diet_restriction.diet_restriction.name : nil
    else
      @staff_count = staff_count
      @diet_restriction = diet_restriction     
      @diet_restriction_id = diet_restriction.id
      @appointment = appointment
    end
  end

  def set_staff_count(count)
    @staff_count = count
  end

end
