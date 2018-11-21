class Admin::Offices::SlotsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate]

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def set_record
    @office = Office.find(params[:office_id])
    @record = AppointmentSlot.find(params[:id])
  end

  def show

  end

  def new
    @day = params[:day]

    @record = AppointmentSlot.new(office_id: @office.id, day_of_week: @day.downcase, staff_count: @office.total_staff_count || 1)
  end

  def edit
    @day = @record.day_of_week
  end

  def copy
    @day = params[:day]
    if @xhr
      render json: { html: (render_to_string :partial => 'copy', :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  def create_copy
    source_day = params[:source_day]
    destination_day = params[:day]

    slots = AppointmentSlot.active.where(office: @office, day_of_week: AppointmentSlot.day_of_weeks[source_day.to_sym])
    existing_slots = AppointmentSlot.active.where(office: @office, day_of_week: AppointmentSlot.day_of_weeks[destination_day.to_sym])
    existing_slots.each do |s|
      s.update_attributes(:status => 'inactive', :deactivated_at => Time.now, :deactivated_by_id => current_user.id)
    end

    slots.each do |slot|
      s = slot.dup
      s.starts_at = s.starts_at(true)
      s.ends_at = s.ends_at(true)
      s.day_of_week = AppointmentSlot.day_of_weeks[destination_day.to_sym]
      s.save
    end

    flash[:notice] = "Appointment slots have been copied from #{source_day} to #{destination_day}."

    redirect_to admin_office_slots_path(@office)

  end

  def create
    slot_form = Forms::AdminSlot.new(current_user, slot_params, @office, nil)
    unless slot_form.save
      render :json => {success: false, general_error: "Unable to create appointment slot(s) due to the following errors or notices:", errors: slot_form.errors}, status: 500
      return
    end

    flash[:notice] = "Appointment Slot(s) have been created!"
    redirect_to admin_office_slots_path(@office)

  end

  def update

    @record.assign_attributes(slot_params)

    if @record.appointments.count > 0 && (@record.starts_at_changed? || @record.ends_at_changed? || @record.staff_count_changed?)
      #loop through appointments and send notification to associated sales rep
      #added where active clause, assuming appts that are open and havent been completed are set to active
      @record.appointments.where(:status => 'active').each do |appt|
        Managers::NotificationManager.trigger_notifications([113], [@office, appt], {sales_rep: appt.sales_rep})
      end
    end

    unless @record.valid? && @record.save && @record.errors.count == 0
      render :json => {success: false, general_error: "Unable to update appointment slot due to the following errors:", errors: @record.errors.full_messages}, status: 500
      return
    end

    flash[:notice] = "Appointment slot has been updated."
    render :json => {success: true, redirect: admin_office_slots_path(@office) }
    return

  end

  def activate

    previously_active = (@record.deactivated_at != nil) ? true : false

    @record.update_attributes(activated_at: Time.now, deactivated_at: nil, status: "active", activated_by_id: current_user.id)

    flash[:notice] = "Appointment slot '#{@record.name}' has been activated within the LunchPro system. Appointments can now be assigned to this slot."
    render :json => {success: true, redirect: admin_office_slots_path(@office) }
  end

  def deactivate
    @record.update_attributes(deactivated_at: Time.now, status: 'inactive', activated_at: nil, deactivated_by_id: current_user.id)

    flash[:alert] = "Appointment slot '#{@record.name}' has been deactivated within the LunchPro system."
    render :json => {success: true, redirect: admin_office_slots_path(@office) }
  end

private

  def slot_params
    params.require(:appointment_slot).permit!
  end
end