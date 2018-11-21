class LunchproWorker

  include Sidekiq::Worker
  sidekiq_options :retry => false, :backtrace => false

  def perform(*args)

  end

end