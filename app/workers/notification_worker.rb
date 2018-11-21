class NotificationWorker < LunchproWorker
  def perform(*args)
    default_processing_user = (Rails.env.production?) ? User.where(email: 'support@collectivepoint.com').first : User.where(email: 'michael.q.carr@gmail.com').first
    #default_processing_user = User.where(email: 'amanda').first
    if default_processing_user
      Managers::NotificationManager.process_new(5.seconds, default_processing_user)
      #sends a message to the application_core_channel tto refresh the notif dropdown
      #Managers::ActioncableManager.new("app_notification_refresh", "notification_worker").broadcast();
    end
  end
end
