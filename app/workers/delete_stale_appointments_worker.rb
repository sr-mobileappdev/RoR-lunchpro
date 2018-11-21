class DeleteStaleAppointmentsWorker < LunchproWorker

  def perform(*args)
    manager = Managers::AppointmentManager.new()
    manager.delete_stale_pending_appointments
  end
end
