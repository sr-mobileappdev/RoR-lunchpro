class SendResetPasswordWorker < LunchproWorker

  def perform(*args)
    manager = Managers::SendPasswordResetManager.new()
    manager.mass_reset_password
  end
end
