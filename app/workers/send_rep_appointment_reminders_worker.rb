class SendRepAppointmentRemindersWorker < LunchproWorker
	include Sidekiq::Worker
  sidekiq_options queue: 'critical'
  def perform(*args)
    Managers::NotificationTriggerManager.notify_rep_appointments_reminders
  end
end
