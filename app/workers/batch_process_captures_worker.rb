class BatchProcessCapturesWorker < LunchproWorker
	include Sidekiq::Worker
  sidekiq_options queue: 'critical'
  def perform(*args)
    Managers::PaymentManager.batch_process_captures
  end

end