class Office::SlotsController < ApplicationOfficesController

  before_action :set_office, except: [:index]
  before_action :set_record, except: [:index, :show_modal, :create_slot_group, :new, :create, :copy, :create_copy]

  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end

  def set_office
    @office = current_user.user_office.office
  end

  def set_record
    @slot = AppointmentSlot.where(id: params[:id]).first
    redirect_to "/404" if !@slot || @slot.office != @office
  end

  def index
    @slots = []
    slot_ids = nil  
    #set time range
    @office = Office.includes(:appointment_slots, :office_exclude_dates).includes(providers: [:provider_availabilities, :provider_exclude_dates])
    .includes(appointments: [sales_rep: [:company]]).where(:id => current_user.user_office.office.id).first
    time_range = set_time_range()
    if !time_range
      render json: { status: 'success', data:{events: [], slot_ids: nil}} and return
    end
    #if provider_ids are provided, check whether comma separated or already array
    if params[:provider_ids].present?
      if !params[:provider_ids].kind_of?(Array)
        providers = params[:provider_ids].split(",")
      else
        providers = params[:provider_ids]
      end
    end
    manager = Views::OfficeAppointments.new(@office, time_range, current_user, providers, nil, slot_ids)
    @slots = manager.upcoming_by_events_om(nil, false)
    render json: { status: 'success', data:{events: @slots}} and return

  end

  def new
    @slot = AppointmentSlot.new(:day_of_week => params[:day], :status => 'active', :activated_by_id => @modifier_id, :activated_at => Time.now)
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/slots/new_slot', :layout => false, :formats => [:html])}
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    end
  end

  def edit
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/slots/edit_slot', :layout => false, :formats => [:html])}
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    end
  end

  def create
    slot_form = Forms::OfficeManagers::OmSlot.new(current_user, slot_params, @office, nil)
    unless slot_form.save
      render :json => {success: false, general_error: "Unable to create appointment slot(s) due to the following errors or notices:", errors: slot_form.errors}, status: 500
      return
    end

    flash[:success] = "Appointment Slot(s) have been created!"
    redirect_to office_appointments_path
  end


  def create_copy
    source_day = params[:source_day]
    destination_day = params[:day]

    slots = AppointmentSlot.active.where(office: @office, day_of_week: AppointmentSlot.day_of_weeks[source_day.to_sym])
    existing_slots = AppointmentSlot.active.where(office: @office, day_of_week: AppointmentSlot.day_of_weeks[destination_day.to_sym])
    existing_slots.each do |s|
      s.deleted!
    end

    slots.each do |slot|
      s = slot.dup
      s.starts_at = s.starts_at(true)
      s.ends_at = s.ends_at(true)
      s.day_of_week = AppointmentSlot.day_of_weeks[destination_day.to_sym]
      s.save
    end

    flash[:notice] = "Appointment slots have been copied from #{source_day} to #{destination_day}."

    redirect_to office_appointments_path

  end

  def update
    slot_form = Forms::OfficeManagers::OmSlot.new(current_user, slot_params, @office, @slot)
    unless slot_form.save
      render :json => {success: false, general_error: "Unable to update appointment slot due to the following errors or notices:", errors: slot_form.errors}, status: 500
      return
    end

    flash[:success] = "Appointment Slot(s) have been created!"
    redirect_to office_appointments_path
  end

  def copy
    @day = params[:day]
    if @xhr
      render json: { html: (render_to_string :partial => 'office/appointments/components/copy', :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end


  def delete
    slot_form = Forms::OfficeManagers::OmSlot.new(current_user, nil, @office, @slot, @modifier_id)
    unless slot_form.delete
      render :json => {success: false, general_error: "Unable to update appointment slot due to the following errors or notices:", errors: slot_form.errors}, status: 500
      return
    end

    flash[:success] = "Appointment Slot(s) has been deleted!"
    redirect_to office_appointments_path
  end

  def show
    @appointment = Appointment.new(:appointment_on => params[:date], :appointment_slot_id => @slot.id, :origin => 'web')
    @sales_reps = @office.active_reps(true).select("sales_reps.id, (first_name || ' ' || last_name) as name, user_id").to_json
    @companies = Company.select(:id, :name).to_json
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/appointments/om_open_appointment', :layout => false, :formats => [:html])}
        return
      else
        raise "Opening model view without passing is_modal=true"
        redirect_to current_office_calendars_path
      end
    else
      redirect_to current_office_calendars_path
    end

  end

  private

  #sets time_range based on appointments_until if passed in
  def set_time_range
    time_range = nil
    end_date = params[:end_date] 
    if params[:start_date].present? && params[:end_date].present? 
      if @office.appointments_until
        #if start_date is greater than until_date, return empty time range, which returns no slots
        if params[:start_date].to_date > @office.appointments_until
          return time_range

        #set appointments_until as end date
        elsif params[:start_date].to_date <= @office.appointments_until && params[:end_date].to_date > @office.appointments_until
          end_date = @office.appointments_until.to_s
        end
      end
      time_range = Date.parse(params[:start_date])..Date.parse(end_date)
    elsif !params[:start_date].present?
      time_range = Time.zone.now.to_date..Date.parse(end_date)
    else
      time_range = Time.zone.now.to_date.beginning_of_month..Time.zone.now.to_date.end_of_month
    end
    return time_range
  end

  def office_params
    params.require(:office).permit(appointment_slots_attributes: [:id, :deactivated_by_id, :activated_by_id, :activated_at, 
      :staff_count, :slot_count, :starts_at, :ends_at, :slot_type, :name, :_destroy, :status, :office_id, :day_of_week])
  end

  def slot_params
    params.require(:appointment_slot).permit(:activated_at, :activated_by_id, :status, :slot_type, :starts_at, :ends_at, :days, :staff_count, :day_of_week)
  end
end