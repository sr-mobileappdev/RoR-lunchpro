class NotifyTodaysOrdersWorker < LunchproWorker

  def perform(*args)
    Managers::NotificationTriggerManager.notify_todays_orders
  end
end
