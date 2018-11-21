class Forms::AdminAppointment < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :appointment
  attr_reader :user

  def initialize(user, params = {}, existing_appointment = nil)
    @current_user = user
    @params = params
    @errors = []

    @appointment = existing_appointment
  end

  def valid?
    raise "Missing required parameters (:appointment)" unless @params[:appointment]

    # Validate Sales Rep
    @appointment ||= Appointment.new(status: 'active', created_by_user_id: @current_user.id)
    @params = @params[:appointment] if @params[:appointment]
    @params = @params.except(:sales_rep) if @params[:sales_rep]
    @appointment.assign_attributes(@params)

    @appointment.origin = 'web'
    unless @appointment.valid?
      @errors += @appointment.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def save
    if persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      notifs = should_trigger_notifications
      if @appointment.save
        trigger_notifications(notifs, [@appointment, @appointment.office, @appointment.sales_rep, @appointment.appointment_slot])
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end

  def should_trigger_notifications
    if @appointment.new_record? && @appointment.sales_rep
      if @appointment.sales_rep.user
        if @current_user.space_admin?
          [112]
        else
          [202] # Rep books appointment
        end
      else
        [201] # Rep books appointment (no LP account)
      end
    elsif @appointment.new_record? && @appointment.sales_rep.nil?
      [117] # Office books internal appointment
    else
      []
    end
  end
end
