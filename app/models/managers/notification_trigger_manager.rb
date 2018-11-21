#this Class is used for triggering notifications based on a cron job
#catch all errors and log 
class Managers::NotificationTriggerManager
  attr_reader :event
  attr_reader :errors


  def self.notify_rep_appointments_reminders
    @errors = []
    return if Date.today.saturday? || Date.today.sunday?
    begin
      remind_date = Date.today + 2.days
      if remind_date.saturday? || remind_date.sunday?
        remind_date += 2.days
      end

      appointments = Appointment.joins(:sales_rep).includes(:sales_rep).where("appointment_on = ? and appointments.status = 1 and sales_reps.status = 1 
        and sales_reps.user_id is not null", remind_date).order(:sales_rep_id)

      manager = Managers::NotificationManager.new()
      if appointments.any?
        appointments.each do |appt|
          manager.cron_trigger_notifications([411], [appt, appt.sales_rep, appt.office])
        end
      end
    rescue Exception => ex
      Rollbar.error("NotifyRepAppointmentsReminders: " + ex.message)
    ensure
      #logging system
    end

  end

  #this method is to notify to order food for their appointment tomorrow if they havent already
  def self.notify_rep_order_food_for_appointment
    @errors = []
    begin
      time_range = DateTime.parse((Time.now.utc + 1.day - 10.minutes).to_s)..DateTime.parse((Time.now.utc + 1.day + 10.minutes).to_s)
      appointments = Appointment.select{|appt| appt.active? && appt.sales_rep && !appt.food_ordered? && 
        !appt.will_supply_food && time_range.cover?(appt.appointment_time)}
      manager = Managers::NotificationManager.new()
      
      if appointments.any?
        appointments.each do |appt|
          manager.cron_trigger_notifications([415], [appt, appt.sales_rep, appt.office])
        end
        if manager.errors.any?
          @errors += manager.errors
        end
      else

      end
    rescue Exception => ex
      Rollbar.error("NotifyAppointmentConfirmationRequest: " + ex.message)
    ensure
      #logging system
    end
  end

  #this method is used to send reps a reminder to confirm or order food for their appt 72 hours prior
  def self.notify_appointment_confirmation_request
    @errors = []
    begin
      time_range = DateTime.parse((Time.now.utc + 3.day - 10.minutes).to_s)..DateTime.parse((Time.now.utc + 3.day + 10.minutes).to_s)
      appointments = Appointment.select{|appt| appt.active? && appt.sales_rep &&
        time_range.cover?(appt.appointment_time)}
      manager = Managers::NotificationManager.new()
      
      if appointments.any?
        appointments.each do |appt|
          manager.cron_trigger_notifications([411], [appt, appt.sales_rep, appt.office])
        end
        if manager.errors.any?
          @errors += manager.errors
        end
      else

      end
    rescue Exception => ex
      Rollbar.error("NotifyAppointmentConfirmationRequest: " + ex.message)
    ensure
      #logging system
    end
  end

  #this method is used to send office an alert that a rep has not confirmed an appt for tomorrow
  def self.notify_office_appointments_unconfirmed
    @errors = []
    begin
      time_range = DateTime.parse((Time.now.utc + 1.day - 10.minutes).to_s)..DateTime.parse((Time.now.utc + 1.day + 10.minutes).to_s)

      appointments = Appointment.includes(:office).where('appointments.status = 1 and sales_rep_id is not null and 
        rep_confirmed_at is null').select{|appt| appt.office.internal? && time_range.cover?(appt.appointment_time)}

      manager = Managers::NotificationManager.new()
      
      if appointments.any?
        appointments.each do |appt|
          manager.cron_trigger_notifications([414], [appt, appt.sales_rep, appt.office])
        end
        if manager.errors.any?
          @errors += manager.errors
        end
      else

      end
    rescue Exception => ex
      Rollbar.error("NotifyAppointmentConfirmationRequest: " + ex.message)
    ensure
      #logging system
    end
  end

  #this method is used to iterate through all active restaurants and 
  #notify their restaurant mangers of their orders for the day
  def self.notify_todays_orders
    @errors = []
    begin 

      restaurants = Restaurant.joins(orders: [:appointment]).where("restaurants.status = 1 and orders.status = 1
        and orders.appointment_id is not null and appointments.appointment_on = ?", Time.now.to_date).group(:id)
    
      manager = Managers::NotificationManager.new()
      if restaurants.any?
        restaurants.each do |rest|
          manager.cron_trigger_notifications([406], [rest])
        end
        if manager.errors.any?
          @errors += manager.errors
        end
      else

      end
    rescue Exception => ex
      Rollbar.error("NotifyTodaysOrders: " + ex.message)
    ensure      
      #logging system
    end
  end

  #this method is used to iterate all active offices and check if their calendar
  #is closing in two weeks time, if true then notify
  def self.notify_calendar_closing
    @errors = []
    begin
      offices = Office.where(:status => 'active', :appointments_until => (Time.now.to_date + 2.weeks))
      manager = Managers::NotificationManager.new()
      if offices.any?
        offices.each do |office|
          manager.cron_trigger_notifications([410], [office])          
        end
        if manager.errors.any?
          @errors += manager.errors
        end
      else

      end
    rescue Exception => ex
      Rollbar.error("NotifyCalendarClosing: " + ex.message)
    ensure
      #logging system
    end
  end

  #this method will notify an admin of all non lp orders set for the next day if any orders exist
  def self.notify_non_lp_orders
    @errors = []
    begin
      orders = Order.non_lp_orders_for_tomorrow
      manager = Managers::NotificationManager.new()
      if orders.any?
        manager.cron_trigger_notifications([407], [])
        if manager.errors.any?
          @errors += manager.errors
        end
      else

      end

    rescue Exception => ex
      Rollbar.error("NotifyNonLpOrders: " + ex.message)
    ensure
      #logging system
    end
  end

  def self.notify_unconfirmed_orders
    @errors = []
    begin
      restaurants = Restaurant.joins(orders: [:appointment]).where("restaurants.status = 1 and orders.status = 1 
        and appointments.restaurant_confirmed_at is null and appointments.appointment_on >= ? and orders.created_at <= ?",
        Time.now.utc.to_date, Time.now.utc - 2.days)

      manager = Managers::NotificationManager.new()
      if restaurants.any?
        restaurants.each do |rest|
          manager.cron_trigger_notifications([408], [rest])
        end
        if manager.errors.any?
          @errors += manager.errors
        end
      else

      end

    rescue Exception => ex
      Rollbar.error("NotifyUnconfirmedOrders: " + ex.message)
    ensure
      #logging system
    end
  end

  def self.notify_next_weeks_appointments
    @errors = []
    begin

      sales_reps = SalesRep.select{|rep| rep.active?}
      manager = Managers::NotificationManager.new()
      if sales_reps.any?
        sales_reps.each do |rep|         
          if rep.next_weeks_appointments.any?
            manager.cron_trigger_notifications([403], [rep])
          else
            manager.cron_trigger_notifications([404], [rep])
          end
        end
        if manager.errors.any?
          @errors += manager.errors
        end

      else

      end
    rescue Exception => ex
      Rollbar.error("NotifyNextweeksAppointments: " + ex.message)
    ensure
      #logging system
    end
  end

  def self.prompt_order_reviews
    @errors = []
    begin

      time_range = (Time.now.utc - 1.day - 10.minutes)..(Time.now.utc - 1.day + 10.minutes)      
      orders = Order.joins(:office).includes(appointment: [:office]).where.not(completed_at: nil, status: 'deleted').where('(offices.internal = true)
        and appointments.appointment_on >= ?', Time.now.to_date - 2.day).
      select{|order| time_range.include?(order.appointment.appointment_end_time)}

      manager = Managers::NotificationManager.new()
      orders.each do |order|
        manager.cron_trigger_notifications([409], [order, order.appointment.sales_rep, order.appointment.office, order.appointment, order.restaurant])
      end
    rescue Exception => ex
      Rollbar.error("NotifyNextweeksAppointments: " + ex.message)
    ensure
      #logging system
    end
  end

end

