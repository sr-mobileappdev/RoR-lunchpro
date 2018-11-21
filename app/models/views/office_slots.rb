class Views::OfficeSlots
  # Decoration / View methods for display of various details
  attr_reader :date
  attr_reader :office
  attr_reader :user

  attr_reader :office_slots

  def initialize(office, date, user = nil, providers = nil, slots = nil, include_inactive_slots = true)
    @office = office
    @date = date
    @user = user
    @providers = providers
    @slots = slots
    @exclusion_dates = @office.office_exclude_dates.to_a if @office
    @office_slots = []
   
    day_appointments = @office.appointments.select{|a| a.appointment_on == @date}
    office_slots_by_day(office, date, include_inactive_slots).each do |slot|
      appt = day_appointments.select {|a| a.appointment_slot_id == slot.id && ["active","pending", "completed"].include?(a.status)}.first
      if (appt && !appt.excluded && @user && @user.space == "space_sales_rep") || !appt || !@user || (appt && @user && @user.space == "space_office")
        @office_slots << Views::Slot.new( date, slot, appt )
      end
    end
  end

  def flattened_events(return_count = nil, office_view = nil)
    events = []
    #return nothing if user is blacklisted
    return events if @office && @user.sales_rep && @user.sales_rep.listed_type(@office) == 'blacklist'
    
    #@office_slots.each_with_index do |slot, index|
    office_slots_organized = @office_slots.select {|slot| slot.frontend_class_name_office(@user) == "current-pending" }.each_with_index do |slot, index| #pending booking
      name = (slot.appointment_slot) ? slot.appointment_slot.name : ''
      if office_view
        if events.any? {|a| a[:date] == @date}
          #already added
        else 
          events << {id: slot.appointment_slot.id, title: "#{name}", start: slot.start_time_on_day(@date), end: slot.end_time_on_day(@date), className: slot.frontend_class_name_office(@user), excluded: (slot.appointment && slot.appointment.excluded), date: @date }
        end
      else
        events << {id: slot.appointment_slot.id, title: "#{name}", start: slot.start_time_on_day(@date), end: slot.end_time_on_day(@date), className: slot.frontend_class_name, excluded: (slot.appointment && slot.appointment.excluded), date: @date }
      end

      break if return_count && ((index + 1) >= return_count)
    end
    
    office_slots_organized = @office_slots.select {|slot| slot.booked_by_rep == @user.sales_rep }.each_with_index do |slot, index| #booked by current or partner rep
      name = (slot.appointment_slot) ? slot.appointment_slot.name : ''
      if office_view
        if events.any? {|a| a[:date] == @date}
          #already added
        else 
          events << {id: slot.appointment_slot.id, title: "#{name}", start: slot.start_time_on_day(@date), end: slot.end_time_on_day(@date), className: slot.frontend_class_name_office(@user), excluded: (slot.appointment && slot.appointment.excluded), date: @date }
        end
      else
        events << {id: slot.appointment_slot.id, title: "#{name}", start: slot.start_time_on_day(@date), end: slot.end_time_on_day(@date), className: slot.frontend_class_name, excluded: (slot.appointment && slot.appointment.excluded), date: @date }
      end

      break if return_count && ((index + 1) >= return_count)
    end

    office_slots_organized = @office_slots.select {|slot| slot.frontend_class_name == "open" }.each_with_index do |slot, index| #open slots only
      name = (slot.appointment_slot) ? slot.appointment_slot.name : ''
      if office_view
        if events.any? {|a| a[:date] == @date}
          #already added
        else
          events << {id: slot.appointment_slot.id, title: "#{name}", start: slot.start_time_on_day(@date), end: slot.end_time_on_day(@date), className: slot.frontend_class_name_office(@user), excluded: (slot.appointment && slot.appointment.excluded), date: @date }
        end
      else
        events << {id: slot.appointment_slot.id, title: "#{name}", start: slot.start_time_on_day(@date), end: slot.end_time_on_day(@date), className: slot.frontend_class_name, excluded: (slot.appointment && slot.appointment.excluded), date: @date }
      end

      break if return_count && ((index + 1) >= return_count)
    end

    events
  end

  def flattened_events_api(return_count = nil)
    #@user == @sales_rep
    events = []
    @office_slots.each_with_index do |slot, index|
    	booked_by_sales_rep = nil
    	if slot.appointment.present? && slot.appointment.status != 'pending'
    		booked_by_sales_rep = slot.booked_by_rep_api
    	end
      	name = (slot.appointment_slot) ? slot.appointment_slot.name : ''
      	events << {id: slot.appointment_slot.id, slot_date: @date, title: "#{name}", start: slot.start_time_on_day(@date, true).strftime("%Y-%m-%dT%H:%M:%S.000Z"), end: slot.end_time_on_day(@date, true).strftime("%Y-%m-%dT%H:%M:%S.000Z"), office_id: slot.office_id, total_staff_count: slot.appointment_slot.total_staff_count, sales_rep: booked_by_sales_rep, available_providers: slot.available_providers}
      	break if return_count && ((index + 1) >= return_count)	
    end

    events
  end

  def flattened_events_om(return_count = nil)
    #@user == @sales_rep
    events = []

    slot_excluded = date_excluded?

    @office_slots.each_with_index do |slot, index|
      name = slot.appointment_slot.name
      className = slot.om_frontend_class_name
      if slot_excluded
       events << {id: slot.appointment_slot.id, className: "excluded", slot_date: @date, start: slot.start_time_on_day(@date), end: slot.end_time_on_day(@date)}
      else
        if className == "open"
          next if (slot.appointment_slot.slot_time(true, @date) < Time.now.in_time_zone(@office.timezone))
          total_staff_count = slot.appointment_slot.total_staff_count(@providers, @date)
        end
        if (@date > DateTime.now - (1.0)) || (className != 'open' && @date < DateTime.now - (1.0))
          events << {id: slot.appointment_slot.id, excluded: slot.appointment ? slot.appointment.excluded : nil, 
            appointment_title: slot.appointment ? slot.appointment.title : nil, className: className, 
            appointment_id: slot.appointment ? slot.appointment.id : nil, company: slot.booked_by, 
            slot_date: @date, title: "#{name}", start: slot.appointment_start_time_on_day(@date), end: slot.appointment_end_time_on_day(@date),
            total_staff_count: total_staff_count, restaurant: slot.appointment ? slot.appointment.restaurant_name(true) : "TBD",
            sales_rep: (slot.appointment && slot.appointment.sales_rep) ? slot.appointment.sales_rep.display_name : "N/A",
            key: slot.appointment_slot.calendar_key}
        end
      end  
      break if return_count && ((index + 1) >= return_count)
    end

    events
  end

private

  def office_slots_by_day(office, date, include_inactive_slots)
  
  	valid_slot_statuses = ['active']
  	
  	if(include_inactive_slots)
  		valid_slot_statuses << 'inactive'
  	end
  	
    # wday starts on Sunday, whereas our day_of_week starts on Monday, so adjust for this:
    day_integer = date.wday

    #return nothing if user is blacklisted
    return [] if @office && @user && @user.sales_rep && @user.sales_rep.listed_type(@office) == 'blacklist'
    #filter by provider logic
    if @providers
      # get providers from list of ids
      pros = Provider.find(@providers).to_a
      allSlots = office.appointment_slots.select{|s| valid_slot_statuses.include?(s.status)}

      
      #filter through slots and exclude any slots where at least one of the providers have that date excluded
      #and where at least one isn't available for that slot
      allSlots = allSlots.select {|slot| 
        @providers.length && ((@providers & office.providers_available_at(slot, true, @providers, date)).length == @providers.length)

      }
      office.appointment_slots.select{|s| allSlots.pluck(:id).include?(s.id) && AppointmentSlot.day_of_weeks[s.day_of_week] == day_integer &&
      s.slot_time(true, date) > Time.now.in_time_zone(office.timezone)}
    else
      if date == Time.now.to_date && @user && @user.space == "space_sales_rep"
        office.appointment_slots.select{|s| valid_slot_statuses.include?(s.status) && AppointmentSlot.day_of_weeks[s.day_of_week] == day_integer&&
        s.slot_time(true, date) > Time.now.in_time_zone(office.timezone)}
      else 
        office.appointment_slots.select{|s| valid_slot_statuses.include?(s.status) && AppointmentSlot.day_of_weeks[s.day_of_week] == day_integer}
        
      end
    end
  end

  def date_excluded?
    if @exclusion_dates.any?
      @exclusion_dates.select {|excl| (excl.starts_at.to_date..excl.ends_at.to_date).include?(@date)}.any?
    else
      false
    end
  end

  # def date_week_range(day)
  #   day.beginning_of_week...day.ending_of_week
  # end

end
