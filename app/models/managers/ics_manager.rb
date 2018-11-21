class Managers::IcsManager
  attr_reader :event
  attr_reader :errors
  attr_reader :notification_objects
  attr_reader :user
  attr_reader :subject

  def initialize(notification_objects = nil, user = nil, cid = nil)    
    @errors = []
    @event = nil
    @notification_objects = notification_objects
    @user = user
    @cid = cid.to_i
  end

  def create_cal
    return nil if !@notification_objects
    office = Office.find(@notification_objects["office_id"]) if @notification_objects["office_id"]
    appt = Appointment.find(@notification_objects["appointment_id"]) if @notification_objects["appointment_id"]

    return nil if !appt || !office
    office_events = [103, 104, 112, 117, 201, 202, 203, 204, 205, 206]
    rep_events = [103, 104, 112, 201, 202, 204, 205, 416]
    alarm_events = [112, 117, 201, 202, 203, 205, 206, 416]

    if user.entity && user.entity.kind_of?(SalesRep) && rep_events.include?(@cid)
      cal = Icalendar::Calendar.new
      if alarm_events.include?(@cid)
        cal.event do |e|
          e.dtstart     = appt.appointment_time(true)
          e.dtend       = appt.appointment_end_time(true)
          e.summary     = office.name
          e.location    = office.display_location_single
          e.organizer   = "mailto:support@lunchpro.com"
          e.organizer   = Icalendar::Values::CalAddress.new("mailto:support@lunchpro.com", cn: 'LunchPro')
            e.alarm do |a|
              a.action  = "DISPLAY" # This line isn't necessary, it's the default
              a.summary = "Event Reminder"
              a.trigger = "-PT1H" # 1 day before
            end
        end
      else
        cal.event do |e|
          e.dtstart     = appt.appointment_time(true)
          e.dtend       = appt.appointment_end_time(true)
          e.summary     = office.name
          e.location    = office.display_location_single
          e.organizer   = "mailto:support@lunchpro.com"
          e.organizer   = Icalendar::Values::CalAddress.new("mailto:support@lunchpro.com", cn: 'LunchPro')
        end
      end
      cal.publish
      @subject = cal.events.first.summary
      cal.to_ical
    elsif user.entity && user.entity.kind_of?(Office) && office_events.include?(@cid)
      rep = SalesRep.find(@notification_objects["sales_rep_id"]) if @notification_objects["sales_rep_id"]
      cal = Icalendar::Calendar.new
      if appt.restaurant
        restaurant_name = appt.restaurant.name
      else
        restaurant_name = "Restaurant TBD"
      end
      if @cid == 117
        summary = appt.title
      else
        summary = "#{rep.display_name} - #{rep.company_name}"
      end

      if alarm_events.include?(@cid)
        cal.event do |e|
          e.dtstart     = appt.appointment_time(true)
          e.dtend       = appt.appointment_end_time(true)
          e.summary     = summary
          e.location    = restaurant_name
          e.organizer   = "mailto:support@lunchpro.com"
          e.organizer   = Icalendar::Values::CalAddress.new("mailto:support@lunchpro.com", cn: 'LunchPro')
            e.alarm do |a|
              a.action  = "DISPLAY" # This line isn't necessary, it's the default
              a.summary = "Event Reminder"
              a.trigger = "-PT1H" # 1 day before
            end
        end
      else
        cal.event do |e|
          e.dtstart     = appt.appointment_time(true)
          e.dtend       = appt.appointment_end_time(true)
          e.summary     = summary
          e.location    = restaurant_name
          e.organizer   = "mailto:support@lunchpro.com"
          e.organizer   = Icalendar::Values::CalAddress.new("mailto:support@lunchpro.com", cn: 'LunchPro')
        end
      end
      cal.publish
      @subject = cal.events.first.summary
      cal.to_ical
    end
  end

end
