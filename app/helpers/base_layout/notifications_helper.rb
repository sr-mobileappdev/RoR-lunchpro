module BaseLayout::NotificationsHelper

  def notification_title(notif = nil)
    return "" unless notif
    recipient_type = notif.user.notification_recipient_type
    notif.web_title(recipient_type)
  end

  def notification_details(notif = nil)

  end

  def notification_time(notif = nil)
    return "" unless notif
    date = notif.latest_notified_date
    if date
      if Time.now.to_date - 1.day == date.to_date
        # Yesterday
        date.strftime("Yesterday at %l:%M %P")
      elsif Time.now.to_date == date.to_date
        # Today
        time_ago(date)
        #date.strftime("Yesterday at %l:%M %P")
      else
        date.strftime("%b %e at %l:%M %P")
      end
    else
      ""
    end
  end

end


def short_date(date, default = nil)
  
  date = parse_date(date)
  return date if date && date.kind_of?(String)
  if default
    return default unless date
  end

  return "" if date == nil
  date.strftime("%a, %b %e")
end
