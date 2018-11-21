class Views::Slot
  # Decoration / View methods for display of various details
  attr_reader :date
  attr_reader :appointment
  attr_reader :appointment_slot
  attr_reader :sales_rep
  attr_reader :state
  attr_reader :office_id
  attr_reader :available_providers
  attr_writer :providers

  def initialize(date, slot, appointment = nil)
    @date = date
    @appointment_slot = slot
    @appointment = appointment
    @office_id = slot.office_id

    if @appointment
      @state = :reserved
      @sales_rep = @appointment.sales_rep
    else
      @state = :available
      @sales_rep = nil
    end
  end

  def is_booked?
    (@state && @state == :reserved)
  end

  def is_booked_pending?
    (@state && @state == :reserved && @appointment && @appointment.status == 'pending')
  end

  def is_booked_active?
     (@state && @state == :reserved && @appointment && @appointment.status == 'active')
  end

  def is_booked_confirmed?
    (@state && @state == :reserved && @appointment && @appointment.rep_confirmed)
  end

  def is_booked_confirmed_om?
    (@state && @state == :reserved && @appointment && @appointment.office_confirmed)
  end

  def is_completed?
    (@state && @state == :reserved && @appointment && @appointment.status == 'completed')
  end
  #used to check if slot is reserved by other sales rep
  def is_reserved_other_rep?(current_user = nil)
    if @appointment && @appointment.sales_rep_id != current_user.sales_rep.id
      true
    else
      false
    end
  end

  def is_reserved_by_partner?(current_user = nil)
    if @appointment && current_user
      (current_user.sales_rep.sales_rep_partners.accepted.pluck(:partner_id)).include?(@appointment.sales_rep_id.to_i)
    else
      false
    end
  end

  #used to check if slot is reserved by other sales rep
  def is_reserved_other_rep_api?(rep = nil)
    if @appointment && @appointment.sales_rep_id != rep.id
      true
    else
      false
    end
  end

  def pending_reservation?
    if @appointment
      true
    else
      false
    end
  end

  def suggested_count
    @appointment_slot.staff_count || "--"
  end

  def available_providers
    @providers ||= set_available_providers
  end

  def start_time_on_day(day, in_zone = false)
    time = @appointment_slot.starts_at(true)
    date = time.on day    
    date
  end

  def end_time_on_day(day, in_zone = false)
    time = @appointment_slot.ends_at(true)
    date = time.on day
    date
  end

  def appointment_start_time_on_day(day, in_zone = false)
    if @appointment != nil
      if @appointment.starts_at != nil
        time = @appointment.starts_at(true)
        date = time.on day    
        date
      else
        time = @appointment_slot.starts_at(true)
        date = time.on day    
        date
      end
    else
      time = @appointment_slot.starts_at(true)
      date = time.on day    
      date
    end
  end

  def appointment_end_time_on_day(day, in_zone = false)
    if @appointment != nil
      if @appointment.ends_at != nil
        time = @appointment.ends_at(true)
        date = time.on day
        date
      else
        time = @appointment_slot.ends_at(true)
        date = time.on day    
        date
      end
    else
      time = @appointment_slot.ends_at(true)
      date = time.on day
      date
    end
  end

  def booked_status(current_user = nil)
    case @state
      when :reserved
        if @sales_rep
          if (current_user && current_user.sales_rep && current_user.sales_rep.id == @sales_rep.id) || 
            (current_user && current_user.sales_rep && is_reserved_by_partner?(current_user))
            "Booked by #{@sales_rep.display_name}"
          else
            "Booked"
          end
        else
          "Booked"
        end
      when :available
        ""
      else

    end
  end

  def frontend_class_name
    if @date && @date < Time.now.to_date
      "past"
    else
      if @state == :reserved
        "booked"
      elsif @state == :available
        "open"
      end
    end
  end

  #used for office view of sales rep
  def frontend_class_name_office(user = nil)
    if @date && @date < Time.now.to_date
      "past"
    else
      if @state == :reserved
        if is_reserved_other_rep?(user) && !is_reserved_by_partner?(user)
          "hidden-booked"          
        else
          if is_booked_pending?
            "current-pending"
          elsif is_reserved_by_partner?(user)
            "current-booked"
          else
            "current-booked"
          end
        end
      elsif @state == :available
        "open"
      end
    end
  end

  #used in office manager calendar
  def om_frontend_class_name
    if @date && @date < Time.now.to_date && @state == :reserved
      "booked"
    elsif @state == :reserved
      if is_booked_confirmed_om?
        "confirmed"
      elsif is_booked_active?
        "booked"
      elsif is_booked_pending?
        "current-pending"
      elsif is_completed?
        "booked"
      end
    else
      "open"
    end
  end

  def status_notice
    if @appointment
      case @appointment.order_state
        when :ordered
          "<span class='badge badge-success'>Ordered</span>".html_safe
        when :pending_order
          "<span class='badge badge-warning'>Pending Food Order</span>".html_safe
      end
    else
      "No Appointment"
    end
  end

  def booked_by
    case @state
      when :reserved
        if @sales_rep
          @sales_rep.company_name
        elsif @appointment && @appointment.internal?
          @appointment.office.name
        end
      when :available
        "Open"
      else
        ""
    end
  end


  def booked_by_rep
    case @state
      when :reserved
        @sales_rep
      when :available
        nil
      else
        ""
    end
  end
  def booked_by_rep_api
  	if !@sales_rep.present?
  		return nil
  	end
  
    case @state
    when :reserved
      if @sales_rep.company
        { id: @sales_rep.id, name: @sales_rep.first_name + " " + @sales_rep.last_name, company: {id: @sales_rep.company.id ,name: @sales_rep.company.name}}
      else
          { id: @sales_rep.id, name: @sales_rep.first_name + " " + @sales_rep.last_name, company: nil}
      end
    when :available
      nil
    else
      ""
    end
  end
private

  def set_available_providers
    @providers = appointment_slot.office.providers_available_at(@appointment_slot, false, nil, @date)
  end

end
