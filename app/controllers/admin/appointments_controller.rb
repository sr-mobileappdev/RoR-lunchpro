class Admin::AppointmentsController < AdminTableController
  # NOTE: Routes file has path for this controller set to /reps/, for visual clarity

  before_action :set_record, only: [:show, :edit, :update, :cancel_popup, :cancel, :edit_notes, :confirm_popup, :confirm]

  def set_record
    @record = Appointment.find(params[:id])
  end

  # -- Scope Table
  def scope_table
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

		default_columns = ['id','office_name','office_location','organizer_name','appointment_date','slot_type','food_column']
    @records = Appointment.none

    # -- Filter / Scope Stuff
    @scope = nil
    scope_params = []
    if params[:scope].present?
      @scope = params[:scope]
      scope_params = Appointment.scope_params_for([@scope])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page)
    else
      @manager = Managers::AdminTableManager.new(Appointment, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page, "appointment_on, starts_at")
    end


  end

  def get_table_path(params)
    admin_appointments_path(params)
  end
  # --

  def index

    @available_scopes = [{scope: 'active', title: 'Active Appointments'}, {scope: 'past', title: 'Past Appointments'}, {scope: 'inactive', title: 'Cancelled Appointments'}]

  end

  def show
    @office = @record.office
  end

  def new
    # Related stories -- Appointment creation


    @record = Appointment.new(created_by_id: current_user.id, timezone: Constants::DEFAULT_TIMEZONE, origin: 'web')
    @record.user = User.new()
  end

  def create

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

    flash[:notice] = "Appointment has been created."
    render :json => {success: true, redirect: admin_appointment_path(appointment) }
    return

  end

  def report
    scope = params[:scope]
    if !scope.present?
      flash[:warning] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    man = Managers::CsvManager.new
    filename = ""

    case scope
      when 'active'
        csv_data = man.generate_upcoming_appointments(current_user)
        filename = "admin_upcoming_appointments"
      when 'past'
        csv_data = man.generate_past_appointments(current_user)
        filename = "admin_past_appointments"
      when 'consolidated'
        csv_data = man.generate_consolidated_appointments_orders(current_user, true)
        filename = "admin_consolidated_appts_orders"
      when 'inactive'
        csv_data = man.generate_cancelled_appointments(current_user, true)
        filename = "admin_cancelled_appointments"
      when 'appmntsFood'
        start_date = params[:start_date] || ((Date.today) + (Date.today.wday - 6) * -1) - 7
        end_date = params[:end_date] || Date.today.to_date
        csv_data = man.generate_booked_appointments_food(current_user, start_date, end_date)
        filename = "booked_appointments_food"
    end


    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data,
      :type => 'text/csv',
      :disposition => "attachment; filename=#{filename}_#{Time.now.to_date}.csv"
  end

  def update

    form = Forms::AdminAppointment.new(current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update appointment due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update appointment at this time due to a server error.", errors: []}, status: 500
      return
    end

    appointment = form.appointment

    flash[:notice] = "Appointment has been updated."
    render :json => {success: true, redirect: admin_appointment_path(appointment) }
    return

  end

  #opens cancel appt popup
  def cancel_popup

    if @xhr
      render json: { html: (render_to_string :partial => 'cancel_form', :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  #opens cancel appt popup
  def confirm_popup

    if @xhr
      render json: { html: (render_to_string :partial => 'confirm_popup', :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  #confirms for both rep and office
  def confirm
    @record.update(:office_confirmed_at => Time.now, :rep_confirmed_at => Time.now, :updated_by_id => current_user.id)
    redirect_to admin_appointment_path(@record)
    return
  end

  def edit_notes

  end

  #cancel appointment
  def cancel

    if params[:cancel_reason].present?

      @record.update_attributes(cancel_reason: params[:cancel_reason], cancelled_at: Time.now, status: "inactive", cancelled_by_id: current_user.id)

      #TODO: send notiication
      if(@record.orders.count > 0)

        @record.orders.each do |order|
          order.update(:status => 'inactive')
          order.line_items.update_all(:status => 'deleted')
        end
        # Trigger Notification 104 - Office: Cancels appointment WITHOUT attached order
        Managers::NotificationManager.trigger_notifications([104], [@record, @record.office, @record.sales_rep, @record.appointment_slot], {sales_rep: @record.sales_rep, office: @record.office})
      else
        # Trigger Notification 103 - Office: Cancels appointment WITH attached order
        Managers::NotificationManager.trigger_notifications([103], [@record, @record.office, @record.sales_rep, @record.appointment_slot], {sales_rep: @record.sales_rep, office: @record.office})
      end

      flash[:alert] = "Appointment has been deleted within the LunchPro system. All orders tied to this appointment have also been cancelled."
      #todo cancel orders tied to appointment

    else
      #todo add client side form validation instead of flash alert
      flash[:alert] = "You must enter a cancellation reason"

    end
    redirect_to admin_office_appointments_path(@record.office)

  end

private

  def allowed_params
    groupings = [:appointment, :user, :office, :sales_rep]

    super(groupings, params)
  end

end
