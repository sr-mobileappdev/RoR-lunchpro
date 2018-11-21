class Rep::CalendarsController < ApplicationRepsController

  before_action :set_rep

  def set_rep
    @sales_rep = current_user.sales_rep
  end
  
  def index
    redirect_to current_rep_calendars_path
  end

  # The current overall calendar for a single rep, across all offices
  def current
    @redirect_to = 'calendar'
    #@time_range = (Time.now.beginning_of_month - 1.week)..(Time.now.end_of_month + 10.days)
    @time_range = Time.now.beginning_of_month.to_date..Time.now.end_of_month.to_date    
  end

  def filter_appointments
    go_to_date = nil
    if params[:month].present?
      begin
        time_range = params[:month].to_date.beginning_of_month..params[:month].to_date.end_of_month
      rescue Exception => ex
      end
    elsif params[:start_date].present? && params[:end_date].present?
      begin
        time_range = Date.parse(params[:start_date])..Date.parse(params[:end_date])
      rescue Exception => ex
      end
    else
      time_range = Time.now.beginning_of_month..Time.now.end_of_month
    end
    slots = Views::SalesRepAppointments.new(current_user.sales_rep, time_range, current_user).upcoming_by_date
    if slots.any?
      slot = slots.sort_by { |k,v| (k.to_date - Time.now.to_date).abs }.first
      go_to_date = slot.first.to_date if slot
    end
    render json: {
      goToDate: go_to_date,
      template: (render_to_string :partial => "rep/calendars/components/appointments",
      locals: {time_range_end: time_range.end, appointment_groups: slots}, :layout => false, :formats => [:html])
    }
  end

  def filter_orders
    if params[:month].present?
      begin
        if params[:month].to_date.end_of_month > Time.now
          time_range = params[:month].to_date.beginning_of_month..Time.now.to_date
        else
          time_range = params[:month].to_date.beginning_of_month..params[:month].to_date.end_of_month
        end
      rescue Exception => ex
      end
    else
      time_range = Time.now.beginning_of_month..Time.now.end_of_month
    end
     render json: {
      template: (render_to_string :partial => "rep/orders/components/orders",
      locals: {slot_manager: Views::SalesRepAppointments.new(current_user.sales_rep, time_range, current_user)}, :layout => false, :formats => [:html])
    }
  end
  # individual calendar for a specific office
  def show

  end

end
