class NotifyNextWeeksAppointmentsWorker < LunchproWorker

  def perform(*args)
    Managers::NotificationTriggerManager.notify_next_weeks_appointments
  end
end
