class Admin::Offices::AppointmentsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def set_record
    @record = Appointment.find(params[:id])
  end

  def index

  end

  def show

  end

  def new
    slot = AppointmentSlot.find(params[:slot_id])
    date = Date.parse(params[:date])

    if slot.deleted?
      flash[:alert] = "Your selected slot is no longer available or has been removed from this office."
      redirect_to admin_office_appointments_path(@office)
    elsif slot.reserved?(date)
      flash[:alert] = "Your selected slot has already been taken."
      redirect_to admin_office_appointments_path(@office)
    end

    @appointment = Appointment.new(appointment_slot_id: slot.id, office_id: @office.id, appointment_on: Date.parse(params[:date]), ends_at: slot.ends_at, 
      starts_at: slot.starts_at, origin: 'web')
	@appointment.adjust_for_dst
    @sales_rep = SalesRep.new
    @sales_rep.sales_rep_emails.build(:email_type => 'business', :status => 'active', :created_by_id => current_user.id) if !@sales_rep.email_exists?("business")
    @sales_rep.sales_rep_phones.build(:phone_type => 'business', :status => 'active', :created_by_id => current_user.id) if !@sales_rep.phone_exists?("business")
  end

  def create

    if params[:create_rep].present? && [1, true, 'true'].include?(params[:create_rep])
      rep_form = Forms::AdminSalesRep.new(current_user, rep_params)
      unless rep_form.valid_for_appointment?
        render :json => {success: false, general_error: "Unable to create new sales rep due to the following errors or notices:", errors: rep_form.errors}, status: 500
        return
      end

      # Model validations & save
      unless rep_form.save_appointment
        render :json => {success: false, general_error: "Unable to create new sales rep at this time due to a server error.", errors: []}, status: 500
        return
      end
      params[:appointment][:sales_rep_id] = rep_form.sales_rep.id
    end
    
    form = Forms::AdminAppointment.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new appointment due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new appointment at this time due to a server error.", errors: []}, status: 500
      return
    end

    appointment = form.appointment

    flash[:notice] = "Appointment has been scheduled. You may now order food or make any necessary changes needed to this appointment."
    render :json => {success: true, redirect: admin_office_appointment_path(appointment.office, appointment) }
    return

  end

  # Return only the table / template results for an appointment calendar by wek
  def list

    week = params[:week]
    year = params[:year]

    week_range = Date.commercial(year.to_i, week.to_i).all_week


    local_vars = {  title: 'Appointments',
                    slot_manager: Views::OfficeAppointments.new(@office, week_range, nil),
                    parent_object: @office }


    render json: { html: (render_to_string :partial => 'admin/shared/components/tables/appointments', locals: local_vars, :layout => false, :formats => [:html]) }
    return
  end

private

  def allowed_params
    groupings = [:appointment]

    super(groupings, params)
  end


private

  def appointment_params
    params.require(:appointment).permit!
  end

  def rep_params
    params.require(:appointment).permit(sales_rep: [:per_person_budget_cents, :first_name, :last_name, :company_id, :default_tip_percent, :max_tip_amount_cents, :company_name,
      sales_rep_emails_attributes: [:email_type, :created_by_id, :status, :id, :email_address], 
      user_attributes: [:primary_phone, :id], sales_rep_phones_attributes: [:phone_type, :created_by_id, :status, :phone_number, :id]])
  end

end
