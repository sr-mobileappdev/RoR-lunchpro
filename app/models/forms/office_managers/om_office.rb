class Forms::OfficeManagers::OmOffice
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :office

  def initialize(user, params = {}, existing_office = nil)
    @current_user = user
    @params = params
    @errors = []
    @notify = false
    @notification = nil
    @office = existing_office

  end

  def valid?
    # Validate office
    #@office ||= Office.new()
    office_sales_reps = @params[:offices_sales_reps_attributes]
    if @params[:appointments_until].present?
      #@notify = true
      #@notification = 102
    elsif office_sales_reps.present? && office_sales_reps["0"][:listed_type] == 'blacklist'
      @office_sales_rep = OfficesSalesRep.find(@params[:offices_sales_reps_attributes]["0"][:id])
      if !(@office_sales_rep.listed_type == 'blacklist')
        @notify = true
        @notification = 118
      end
    end
    @office.assign_attributes(@params)

    unless @office.valid?
      @errors += @office.errors.full_messages
    end
    return (@errors.count == 0)
  end

  def save
    if check_notifications && persist!
      true
    else
      false
    end
  end

  def update_restaurant_exclusions
    ActiveRecord::Base.transaction do
      exclude_ids = @params[:office_restaurant_exclusions].split(",")
      if @office.office_restaurant_exclusions.destroy_all
        exclude_ids.each do |id|
          if @office.office_restaurant_exclusions.find_or_create_by(:restaurant_id => id)

          else
            raise ActiveRecord::Rollback
          end
        end
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end

  def check_notifications
    if @notify && @notification
      #if office updates calendar to be open until farther into future, notify users
=begin      if @notification == 102 && @office.appointments_until > Office.find(@office.id).appointments_until
        @office.active_reps(true).each do |rep|
          byebug
          Managers::NotificationManager.trigger_notifications([102], [@office, rep])  
        end
=end
      #logic for when rep is blocked
      if @notification == 118
        sales_rep = @office_sales_rep.sales_rep
        #loop through future appts and cancel all, send notification
        sales_rep.appointments.select{|appt| appt.office_id == @office.id && appt.appointment_time(true) > Time.now.in_time_zone(appt.office.timezone)}.each do |appt|
          order = appt.active_order
          if order && !order.cancellable?
          else
            appt.update(:status => 'inactive', cancelled_at: Time.now, :cancelled_by_id => @current_user.id)
          end
          if order && order.cancellable?
            order.update(:status => 'inactive')
          end 
        end
        Managers::NotificationManager.trigger_notifications([118], [@office, sales_rep])
      else
        true
      end
    else
      true
    end
  end

  def delete_slots(slot = nil)
    return false if !slot
    slots = AppointmentSlot.where(:status => 'active', :slot_type => slot.slot_type, 
    :starts_at => slot.starts_at, :ends_at => slot.ends_at)
    slots.each do |slot|      
      slot.assign_attributes(:status => 'inactive', :deactivated_at => Time.now, :deactivated_by_id => @current_user.id)
      if !slot.valid?
        @errors << slot.errors.full_messages
      else
        slot.save
      end
    end
    return (@errors.count == 0)
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @office.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
