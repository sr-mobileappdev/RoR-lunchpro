class AppointmentsAndOrdersWorker < LunchproWorker

  def perform(*args)
    manager = Managers::AppointmentManager.new()
    manager.mark_appointments_completed
    Managers::NotificationTriggerManager.prompt_order_reviews
    Managers::NotificationTriggerManager.notify_office_appointments_unconfirmed
  end
end
