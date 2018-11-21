class SetIdempotencyWorker < LunchproWorker

  def perform(*args)
    Managers::OrderManager.set_idempotency_keys
  end
end
