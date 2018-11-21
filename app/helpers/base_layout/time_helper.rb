module BaseLayout::TimeHelper

  def time_ago(time)
    return "" unless time && (time.kind_of?(Time) || time.kind_of?(DateTime))
    if time > Time.zone.now - 2.minutes
      "Now"
    else
      "#{time_ago_in_words(time)} ago"
    end
  end

  def style_slot_time(start_time = nil, end_time = nil)
    return "" unless start_time && end_time
    "#{start_time.strftime('%l:%M')}<em>#{start_time.strftime('%P')}</em> - #{end_time.strftime('%l:%M')}<em>#{end_time.strftime('%P')}</em>".html_safe
  end

  def slot_time(time)
    return "" unless time && time.respond_to?(:strftime)
    "#{time.strftime('%l:%M %p')}"
  end

  def short_date(date, default = nil)

    return date if date && date.kind_of?(String)
    date = parse_date(date)
    if default
      return default unless date
    end

    return "" if date == nil
    date.strftime("%a, %b %e")
  end

  def long_date(date, default = nil)
    date = parse_date(date)
    return date if date && date.kind_of?(String)
    if default
      return default unless date
    end

    return "" if date == nil
    date.strftime("%A, %b %e at %l:%M %P")
  end

  def long_date_minus_15(date, default = nil)
    date = parse_date(date)
    return date if date && date.kind_of?(String)
    if default
      return default unless date
    end

    return "" if date == nil
    date = date - 15.minutes
    date.strftime("%A, %b %e at %l:%M %P")
  end

  def csv_long_date(date, default = nil)
    date = parse_date(date)
    return date if date && date.kind_of?(String)
    if default
      return default unless date
    end

    return "" if date == nil
    date.strftime("%m/%d/%Y at %l:%M %P")
  end

  #june 16th, 2018
  def standard_date(date, default = nil)
    date = parse_date(date)
    return date if date && date.kind_of?(String)
    if default
      return default unless date
    end

    return "" if date == nil
    date.to_date.to_formatted_s(:long_ordinal)
  end
  def simple_date(date = nil, default = nil, no_spaces = false)
    return nil if !date
    date = parse_date(date)
    return date if date && date.kind_of?(String)
    if default
      return default unless date
    end

    return "" if date == nil
    if no_spaces
      date.strftime("%m/%d/%Y")
    else
      date.strftime("%m / %d / %Y")
    end
  end

  def system_date(date)
    return date if date && date.kind_of?(String)

    date.strftime("%Y-%m-%d")
  end

  def hour_value(val)
    return "" unless val
    time = Tod::TimeOfDay.parse "#{val}:00:00"
    "#{time.strftime('%l:%M %p')}"
  end

  def this_month_timeframe(reference_date = nil)
    if reference_date
      (reference_date.beginning_of_month...reference_date.ending_of_month)
    else
      (Time.now.beginning_of_month...Time.now.ending_of_month)
    end
  end

  def days_of_week(params = {})

    days = [['Monday', 'monday'], ['Tuesday', 'tuesday'], ['Wednesday', 'wednesday'], ['Thursday', 'thursday'], ['Friday', 'friday'], ['Saturday', 'saturday'], ['Sunday', 'sunday']]
    if params && params[:except].present?
      days.select { |d| d[1] != params[:except] }
    else
      days
    end
  end

  def short_day_of_week(day)
    return "" if !day
    day[0..2].capitalize
  end
  # Return a future calendar range to show, based on current date
  def calendar_range(start_date = Date.beginning_of_week)
    Time.zone.now.to_date..(start_date + 6.days).to_date
  end


  # -- Helper method in case we need to parse a string rep of a date

  def parse_date(date_val = nil)
    return nil if date_val == nil
    return date_val unless date_val.kind_of?(String)

    begin
      return Date.parse(date_val)
    rescue Exception => ex
      return nil
    end
  end

end
