class Templates::Web::OfficeTemplate < Templates::BaseTemplate
  attr_reader :office

  def initialize(obj = nil)
    @object_type = obj.class
    @office = obj
  end

  def tags
    return [] if !@office
    {
      name: 'name',
      appointments_until_date: 'appointments_until_date'
    }
  end

  def __appointments_until_date
    ApplicationController.helpers.standard_date(@office.appointments_until)
  end
end
