class Forms::FrontendAppointment < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :appointment
  def initialize(user, params = {}, existing_appointment = nil, modifier_id)
    @current_user = user
    @params = params
    @errors = []
    @modifier_id = modifier_id

    @appointment = existing_appointment
  end

  def valid?(check_if_past = false)

    raise "Missing required parameters (:appointment)" unless @params[:appointment]
    if @params[:appointment][:sales_rep_id].present?
      sales_rep_id = @params[:appointment][:sales_rep_id]
    elsif @current_user.sales_rep
      sales_rep_id = @current_user.sales_rep.id
    elsif !@appointment.sales_rep_id && !@params[:appointment][:title].present?
      @errors << "You must provide a sales rep for this appointment."
      return (@errors.count == 0)
    end


    # Validate Sales Rep
    @appointment ||= Appointment.new(status: 'active', created_by_user_id: @modifier_id, sales_rep_id: sales_rep_id)

    if @params[:appointment][:title].present? && !@params[:appointment][:sales_rep_id].present?
      @params[:appointment][:appointment_type] = 'internal'
    end
    #used in OM flow when recommended cuisines
    format_samples_requested
    format_cuisines


    @appointment.assign_attributes(@params[:appointment])

    @appointment.assign_attributes(:updated_by_id => @modifier_id, :origin => 'web')
    if @appointment.non_lp? && @params[:appointment][:will_supply_food].present? && @params[:appointment][:bring_food_notes].present?
      @appointment.assign_attributes(:status => 'active')
    end
    unless @appointment.valid?
      @errors += @appointment.errors.full_messages
    end

    if @appointment.appointment_type == 'internal'
      @appointment.sales_rep_id = nil
    end
    return (@errors.count == 0)
  end

  def save(cancel_orders = false)
    #cancel_orders is used when a rep marks BYO for an appt that has an active order
    if !@appointment.appointment_slot_id.present? && @params[:appointment][:starts_at].present?
      unless convert_local_time_to_utc
        return (@errors.count == 0)
      end
    end
    if cancel_orders && valid? && persist! && cancel_all_orders
      true
    elsif !cancel_orders && valid? && persist!
      true
    else
      false
    end
  end

  def cancel(space = nil)
    raise "Missing required parameters (:appointment)" unless @params[:appointment]

    if !@params[:appointment][:cancel_reason].present? && @current_user.space != 'space_office'
      @errors << "You must provide a cancelation reason."
      return (@errors.count == 0)
    end

    order = @appointment.active_order
    admin_user = User.where(:id => @modifier_id).first
    if space && space == 'space_office' && admin_user && admin_user.space_admin?
      if order
        # Trigger Notification 104 - Office: Cancels appointment WITH attached order
        Managers::NotificationManager.trigger_notifications([104], [@appointment, @appointment.office, @appointment.sales_rep, 
          @appointment.appointment_slot, order])
      else
        # Trigger Notification 103 - Office: Cancels appointment WITHOUT attached order
        Managers::NotificationManager.trigger_notifications([103], [@appointment, @appointment.office, @appointment.sales_rep, 
          @appointment.appointment_slot])
      end
    elsif space && space == 'space_sales_rep' && admin_user && admin_user.space_admin?
      if order
        # Trigger Notification 204 - Rep: Cancels appointment WITH attached order
        Managers::NotificationManager.trigger_notifications([204], [@appointment, @appointment.office, @appointment.sales_rep, 
          @appointment.appointment_slot, order])
      else
        # Trigger Notification 205 - Rep: Cancels appointment WITHOUT attached order
        Managers::NotificationManager.trigger_notifications([205], [@appointment, @appointment.office, @appointment.sales_rep, 
          @appointment.appointment_slot])
      end
    end

    @appointment.update(:cancel_reason => @params[:appointment][:cancel_reason], :cancelled_at => Time.now, :cancelled_by_id => @modifier_id, 
      :status => 'inactive', :updated_by_id => @modifier_id)
    @appointment.orders.each do |order|
      order.update(:status => 'inactive', :updated_by_id => @modifier_id, :cancelled_at => Time.now, :cancelled_by_id => @modifier_id)
      order.line_items.update_all(:status => 'deleted')
    end

    unless @appointment.valid?
      @errors += @appointment.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def cancel_all_orders
    #if BYO is set, will override any current orders, and set food_ordered to false
    order = appointment.active_order
    order.update(:status => 'inactive', :updated_by_id => @modifier_id, :cancelled_at => Time.now, :cancelled_by_id => @modifier_id) if order
    
    @appointment.update(:food_ordered => false, :updated_by_id => @modifier_id)

    return (@errors.count == 0)
  end

  def confirm_appointments(appts, book_duplicates = false)
    return [] if !appts || !appts.any?
    ActiveRecord::Base.transaction do
      duplicate_appts = []
      if !book_duplicates
        duplicate_appts = @current_user.sales_rep.check_for_duplicate_appointments(appts)
        appts = appts - duplicate_appts
      end
      appts.each do |appt|
        unless appt.update(:status => 'active', :updated_by_id => @modifier_id)
          @errors += appt.errors.full_messages
          raise ActiveRecord::Rollback
          return []
        end
      end
      return duplicate_appts
    end
    return []
  end

  def cancel_appointments(appts = [])
    return true if !appts || !appts.any?
    ActiveRecord::Base.transaction do
      appts.each do |appt|
        unless appt.update(:status => 'inactive', :updated_by_id => @modifier_id, :cancelled_by_id => @modifier_id, :cancelled_at => Time.now)
          @errors += appt.errors.full_messages
          raise ActiveRecord::Rollback
          return false;
        end
      end
      true    
    end
    return (@errors.count == 0)
  end


private

  def convert_local_time_to_utc
    appointment = @params[:appointment]
    time_manager = Managers::TimeManager.new(@appointment.starts_at, @appointment.appointment_on, @appointment.office_id)
    time = time_manager.time_converted_to_utc
    unless time
      @errors << "An error occured while creating this appointment"
      false
    end
    @params[:appointment][:starts_at] = time
    @appointment.starts_at = time
    true
  end
  def persist!
    ActiveRecord::Base.transaction do
      #notifs = should_trigger_notifications
      if @appointment.save && check_if_past
        #trigger_notifications(notifs, [@appointment, @appointment.office, @appointment.sales_rep, @appointment.appointment_slot])
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end

  def check_if_past
    if Time.now > @appointment.appointment_time
      @errors << "You cannot create an appointment in the past."
      return false
    end
    true
  end

  def should_trigger_notifications
    if @appointment.new_record? && @appointment.sales_rep
      if @appointment.sales_rep.user
        if @appointment.created_by_office?
          [112]
        else
          [202] # Rep books appointment
        end
      else
        [201] # Rep books appointment (no LP account)
      end
    elsif @appointment.new_record? && @appointment.sales_rep.nil?
      if @appointment.internal?
        [117] # Office books internal appointment
      else
        []
      end
    else
      []
    end
  end

  def format_samples_requested
    samples_requested = @params[:appointment][:samples_requested]
    if samples_requested.present? && !samples_requested.kind_of?(Array)
      samples_requested = samples_requested.split(',').map(&:to_i)
      @params[:appointment][:samples_requested] = samples_requested
    elsif samples_requested == ""
      @errors << "You must select at least one drug to request."
      return (@errors.count == 0) 
    end
  end

  def format_cuisines
    recommended_cuisines = @params[:appointment][:recommended_cuisines]
    if recommended_cuisines.present? && !recommended_cuisines.kind_of?(Array)
      recommended_cuisines = recommended_cuisines.split(',').map(&:to_i)
      if @appointment.food_ordered?
        @errors << "You cannot add a cuisine recommendation because food has already been ordered for this appointment."
        return (@errors.count == 0)
      else
        @params[:appointment][:recommended_cuisines] = recommended_cuisines
      end
    elsif recommended_cuisines == ""
      @errors << "You must select at least one cuisine."
      return (@errors.count == 0)
    end
  end
end
