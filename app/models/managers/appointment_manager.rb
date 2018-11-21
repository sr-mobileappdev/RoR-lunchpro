##purpose of this manager is to handle background tasks related to appts
class Managers::AppointmentManager
  attr_reader :errors

  def initialize()
    @errors = []
  end

  #purpose is to delete any appointments that have been 'reserved' but have not be 'confirmed' through the book appt flow
  #we allow a rep to 'reserve' an appt slot for up to an hour in the current cart approach
  #after the hour, we delete these to open the slot up to other reps
  def delete_stale_pending_appointments
    begin
      appts = Appointment.where("status = ? and created_at <= ?", 2, (Time.now.utc - 1.hour))
      appts.update_all(:status => 'deleted', :cancel_reason => "SYSTEM: DeleteStalePendingAppointments", :cancelled_at => Time.now.utc)
    rescue Exception => ex
      Rollbar.error("DeleteStalePendingAppointments: " + ex.message)
    end     
  end

  #purpose of this is to set appointments to completed after their end times
  #allow for a 5 min offset
  def mark_appointments_completed
    begin
      time_range = (Time.now.utc - 10.minutes)..(Time.now.utc + 10.minutes)
      appts = Appointment.includes(:office).where("status = ? and ends_at is not null", 1).select{|appt| time_range.include?(appt.appointment_end_time) || appt.appointment_end_time < Time.now.utc}
      
      non_lp_appts = Appointment.where('status = ? and appointment_slot_id is null and starts_at is not null', 1).select{|appt| time_range.include?(appt.appointment_time + 3.hours) || (appt.appointment_time + 3.hours) < Time.now.utc}

      appts += non_lp_appts
      Appointment.where(:id => appts.pluck(:id)).update_all(:status => 'completed')
    rescue Exception => ex
      Rollbar.error("MarkAppointmentsCompleted: " + ex.message)
    end 
  end

private

end
