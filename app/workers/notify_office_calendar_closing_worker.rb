class NotifyOfficeCalendarClosingWorker < LunchproWorker

  def perform(*args)
    Managers::NotificationTriggerManager.notify_calendar_closing
  end
end
