class Views::OfficeAppointments
  # Decoration / View methods for display of various admin details
  attr_reader :office
  attr_reader :user
  attr_reader :start_date
  attr_reader :end_date
  attr_writer :timeframe

  def initialize(office, timeframe, user = nil, providers = nil, slot_date = nil, slots = nil)
    @office = office
    @user = user
    @slots = slots    #if an array of slot_ids is passed through, use these rather than logic to determining slot_ids
    @timeframe = timeframe
    @slot_date = slot_date
    @start_date = @timeframe.begin.to_date
    @end_date = @timeframe.end.to_date
    @providers = providers

    @exclusion_dates = @office.office_exclude_dates.to_a if @office
  end

  def upcoming_by_date (include_inactive_slots = true)
    # Grouped appointments by date

    appointments = {}
    #if the timerange extends beyond @office.appointments_until, set timeframe to beginning of initial timeframe to the appointments_until date
    if @office && @office.appointments_until && @timeframe.cover?(@office.appointments_until)
      @timeframe = @timeframe.begin..@office.appointments_until
    elsif @office.appointments_until && @timeframe.begin.to_date > @office.appointments_until.to_date
      @timeframe = []
    end

    @timeframe.each do |day|
      if !date_excluded?(day)
        appointments[system_date(day)] = Views::OfficeSlots.new(@office, day, @user, @providers, nil, include_inactive_slots)
      else
         appointments[system_date(day)] = nil
      end
    end

    appointments
  end

  def upcoming_by_events(return_count = nil, office_view = nil, include_inactive_slots = true)
    # Flattened appointments array with no date groupings

    events = []
    @timeframe.each do |day|
      if !date_excluded?(day)
        events += Views::OfficeSlots.new(@office, day, @user, nil, nil, include_inactive_slots).flattened_events(return_count, office_view)
      end
    end

    events
  end

  def upcoming_by_events_api(return_count = nil)
    events = []
    #if specific date is provided, override time frame
    if @slot_date
      events += Views::OfficeSlots.new(@office, @slot_date, @user, nil, nil, false).flattened_events_api(return_count)
    else
      @timeframe.each do |day|
      	if !date_excluded?(day)
        	events += Views::OfficeSlots.new(@office, day, @user, nil, nil, false).flattened_events_api(return_count)
        end
      end
     end
    events
  end

  def upcoming_by_events_om(return_count = nil, include_inactive_slots = true)
    events = []
    @timeframe.each do |day|
      events += Views::OfficeSlots.new(@office, day, @user, @providers, @slots, include_inactive_slots).flattened_events_om(return_count)
    end
    events
  end
private

  def system_date(date)
    return date if date && date.kind_of?(String)

    date.strftime("%Y-%m-%d")
  end


  def date_excluded?(date)
    if @exclusion_dates.any?
      @exclusion_dates.select {|excl| (excl.starts_at.to_date..excl.ends_at.to_date).include?(date)}.any?
    else
      false
    end
  end
end
