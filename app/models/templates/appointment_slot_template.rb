class Templates::AppointmentSlotTemplate < Templates::BaseTemplate
  attr_reader :appointment_slot

  def initialize(obj = nil)
    @object_type = obj.class
    @appointment_slot = obj
  end

  def tags
    {
      
    }
  end


end
