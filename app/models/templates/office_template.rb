class Templates::OfficeTemplate < Templates::BaseTemplate
  attr_reader :office

  def initialize(obj = nil)
    @object_type = obj.class
    @office = obj
  end

  def tags
    return [] if !@office
    {
      name: 'name',
      appointments_until_date: 'appointments_until_date',
      office_policies_url: 'office_policies_url',
      phone: 'phone',
      display_location: 'display_location',
      total_staff_count: 'total_staff_count',
      delivery_instructions: 'delivery_instructions',
      office_url: 'office_url',
      poc_name: 'poc_name',
      poc_email: 'poc_email',
      poc_phone_number: 'poc_phone_number',
      poc_name_or_nil: 'poc_name_or_nil',
      dietary_restrictions: 'dietary_restrictions',
      policies: 'policies'
    }
  end

  def __policies
    @office.office_policy
  end

  def __dietary_restrictions
    @office.food_preferences
  end

  def __poc_name
    if @@options && @@options['poc'].present?
      @@options['poc']['full_name']
    else
      @office.manager_name || @office.name
    end
  end 

  def __poc_name_or_nil
    if @@options && @@options['poc'].present?
      @@options['poc']['full_name']
    else
      @office.manager_name
    end
  end

  def __poc_email
    if @@options && @@options['poc'].present?
      @@options['poc']['email_address']
    else
      @office.manager_email
    end
  end

  def __poc_phone_number
    if @@options && @@options['poc'].present?
      ApplicationController.helpers.format_phone_number_string(@@options['poc']['phone_number'])
    else
      @office.manager_phone || @office.phone
    end
  end

  def __office_url
    UrlHelpers.rep_offices_url(office: @office.id)
  end
  def __appointments_until_date
    ApplicationController.helpers.standard_date(@office.appointments_until)
  end
  def __day_and_time
    ApplicationController.helpers.long_date(@appointment.appointment_time_in_zone)
  end

  def __office_policies_url
    UrlHelpers.policies_rep_appointments_url(office_id: @office.id)
  end


end
