class NotifyNonLpAndUnconfirmedOrdersWorker < LunchproWorker

  def perform(*args)
    Managers::NotificationTriggerManager.notify_non_lp_orders
    Managers::NotificationTriggerManager.notify_unconfirmed_orders
  end
end
