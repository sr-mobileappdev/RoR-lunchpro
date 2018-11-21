class Office::CalendarsController < ApplicationOfficesController

  before_action :set_office, only: [:current]

  def set_office
    @office = Office.includes(:appointment_slots, :providers).where(:id => current_user.user_office.office_id).first
  end

  def index
    redirect_to current_office_calendars_path
  end

  # The current overall calendar for a single rep, across all offices
  def current
    min_slot = @office.appointment_slots.select{|slot| slot.active?}.sort_by{|slot| slot.starts_at(true)}.first
    if min_slot
      @min_time = min_slot.starts_at(true)
    else
      @min_time = "06:00:00"
    end

    max_slot = @office.appointment_slots.select{|slot| slot.active?}.sort_by{|slot| slot.ends_at(true)}.reverse.first
    if max_slot
      @max_time = max_slot.ends_at(true) if max_slot
    else
      @max_time = "21:00:00"
    end
  end

  
  # individual calendar for a specific office
  def show

  end

end
