class Admin::Providers::SlotsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :delete]

  def set_parent_record
    @provider = Provider.find(params[:provider_id]) 
  end

  def set_record
    @record = ProviderAvailability.find(params[:id])
  end

  def show

  end

  def new
    @day = params[:day]
    @record = ProviderAvailability.new(provider_id: @provider.id, day_of_week: @day.downcase)
  
  end
  def providers_available_at(appointment_slot)
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

    slots = ProviderAvailability.active.where(provider_id: @provider.id, day_of_week: ProviderAvailability.day_of_weeks[source_day.to_sym])
    existing_slots = ProviderAvailability.active.where(provider_id: @provider.id, day_of_week: ProviderAvailability.day_of_weeks[destination_day.to_sym])
    existing_slots.each do |s|
      s.deleted!
    end

    slots.each do |slot|
      s = slot.dup
      s.starts_at = slot.starts_at(true)
      s.ends_at = slot.ends_at(true)
      s.day_of_week = ProviderAvailability.day_of_weeks[destination_day.to_sym]
      s.save
    end

    flash[:notice] = "Availability times have been copied from #{source_day} to #{destination_day}."

    redirect_to admin_provider_path(@provider, office_id: @provider.office.id)

  end

  def create

    slot = ProviderAvailability.new(slot_params)

    unless slot.valid? && slot.save && slot.errors.count == 0
      render :json => {success: false, general_error: "Unable to create new appointment slot due to the following errors:", errors: slot.errors.full_messages}, status: 500
      return
    end
    
    notify_rep_new_provider(slot)

    flash[:notice] = "Appointment slot has been added."
    render :json => {success: true, redirect: admin_provider_path(@provider, office_id: @provider.office.id) }
    return

  end

  def update

    oldSlot = @record.dup

    @record.assign_attributes(slot_params)
    unless @record.valid? && @record.save && @record.errors.count == 0
      render :json => {success: false, general_error: "Unable to update appointment slot due to the following errors:", errors: @record.errors.full_messages}, status: 500
      return
    end

    notify_rep_provider_changed(oldSlot)
    
    flash[:notice] = "Appointment slot has been updated."
    render :json => {success: true, redirect: admin_provider_path(@provider, office_id: @provider.office.id) }
    return

  end

  def delete
    @record.deleted!

    flash[:notice] = "Available timeframe has been removed."
    render :json => {success: true, redirect: admin_provider_path(@provider, office_id: @provider.office.id) }
  end


private

  def slot_params
    params.require(:provider_availability).permit!
  end

  #notify reps if new provider is avail
  def notify_rep_new_provider(slot)
    office = slot.provider.office

    #get slots that are on the specific day of week and fall in to the hour range
    slots = office.appointment_slots.where(:day_of_week => slot.day_of_week).where("starts_at >= ? and ends_at <= ?", slot.starts_at.to_s, slot.ends_at.to_s) 

    if slots.count > 0
      #loop through each slot, get sales reps tied to appointments in that slot, loop through each appointment in slot, send notification to sales reps
      slots.each do |slot|
        #added where active clause, assuming appts that are open and havent been completed are set to active
        slot.appointments.where(:status => 'active').each do |appt|       
          #perhaps we will also pass in the provider object eventually
          Managers::NotificationManager.trigger_notifications([113], [office, appt], {sales_rep: appt.sales_rep}) 
        end
      end
    end
  end

  def notify_rep_provider_changed(slot)
    office = slot.provider.office

    #get slots that provider was avail for before the update
    oldSlots = office.appointment_slots.where(:day_of_week => slot.day_of_week).where("starts_at >= ? and ends_at <= ?", slot.starts_at.to_s, slot.ends_at.to_s) 

    #get slots that provider is avail for after the update
    newSlots = office.appointment_slots.where(:day_of_week => @record.day_of_week).where("starts_at >= ? and  ends_at <= ?", @record.starts_at.to_s, @record.ends_at.to_s) 

    #get the slots that the provider is no longer avail for
    lostSlots = oldSlots - newSlots
    #loop through each slot, get sales reps tied to appointments in that slot, loop through each appointment in slot, send notification to sales reps
    lostSlots.each do |slot|
      #added where active clause, assuming appts that are open and havent been completed are set to active
      slot.appointments.where(:status => 'active').each do |appt|       
        #perhaps we will also pass in the provider object eventually, and notification that provider was lost
        Managers::NotificationManager.trigger_notifications([113], [office, appt], {sales_rep: appt.sales_rep}) 
      end
    end

    #get the slots that the provider are newly avail for
    newAvailSlots = newSlots - oldSlots
    #loop through each slot, get sales reps tied to appointments in that slot, loop through each appointment in slot, send notification to sales reps
    newAvailSlots.each do |slot|
      #added where active clause, assuming appts that are open and havent been completed are set to active
      slot.appointments.where(:status => 'active').each do |appt|       
        #perhaps we will also pass in the provider object eventually, and notification that provider was gained
        Managers::NotificationManager.trigger_notifications([113], [office, appt], {sales_rep: appt.sales_rep}) 
      end
    end

  end

end
