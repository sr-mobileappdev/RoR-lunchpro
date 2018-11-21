class Api::Frontend::AppointmentsController < ApplicationController

  before_action :authenticate_user!

  def index
    @user = current_user
    @slots = []
    time_range = Time.zone.now.to_date.beginning_of_week..Time.zone.now.to_date.end_of_week
    go_to_date = nil

    if params[:start_date].present? && params[:end_date].present?
      begin
        time_range = Date.parse(params[:start_date])..Date.parse(params[:end_date])
      rescue Exception => ex
      end
    end
    
    serializable_resource = {}
    if params[:office_id].present?
      @office = Office.find(params[:office_id])
      serializable_resource = { office: OfficesSerializer.new(@office) }
      manager = Views::OfficeAppointments.new(@office, time_range, nil)
      time_range = set_time_range
      if !time_range
        render json: { status: 'success' }.merge(serializable_resource).merge({ data: { events: [] }}) and return
      end
      if params[:for_office]
        manager = Views::OfficeAppointments.new(@office, time_range, current_user)
        @slots = manager.upcoming_by_events(nil, true, false)
      else
        manager = Views::OfficeAppointments.new(@office, time_range, nil)
        @slots = manager.upcoming_by_events(nil)
      end

    elsif params[:sales_rep_id].present?
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      manager = Views::SalesRepAppointments.new(@sales_rep, time_range, nil)
      @slots = manager.upcoming_by_events(1)
    else
      
      if @user.space_sales_rep?
        serializable_resource = { sales_rep: SalesRepsSerializer.new(@user.sales_rep)}
        manager = Views::SalesRepAppointments.new(@user.sales_rep, time_range, nil)
        @slots = manager.upcoming_by_events(1)
        if @slots.any? 
          slot = @slots.sort_by { |slot| (slot[:start].to_date - Time.now.to_date).abs }.first
          go_to_date = slot[:start].to_date if slot
        end
      elsif @user.space_office?
        serializable_resource = { office: OfficesSerializer.new(@user.office)}
        manager = Views::OfficeAppointments.new(@user.office, time_range, nil)
        @slots = manager.upcoming_by_events(1)
      else

      end
    end



    render json: { status: 'success' }.merge(serializable_resource).merge({ data: { events: @slots, goToDate: go_to_date }}) and return

  end

  private

    def set_time_range
    time_range = nil
    if params[:start_date].present? && params[:end_date].present?
      end_date = params[:end_date]  
      if @office.appointments_until
        #if start_date is greater than until_date, return empty time range, which returns no slots
        if params[:start_date].to_date > @office.appointments_until
          return time_range

        #set appointments_until as end date
        elsif params[:start_date].to_date <= @office.appointments_until && params[:end_date].to_date > @office.appointments_until
          end_date = @office.appointments_until.to_s
        end
      end
      time_range = Date.parse(params[:start_date])..Date.parse(end_date)
    else
      time_range = Time.zone.now.to_date..Time.zone.now.to_date.end_of_month
    end
    return time_range
  end
end

# {
#     status: 'success',
#     data: {
#         events: [
#                 {
#                     id: 1,
#                     title: 'Breakfast - Open (15)',
#                     start: '2017-10-09T13:00:00',
#                     end: '2017-10-09T14:00:00',
#                     className: "open"
#                 },
#                 {
#                     id: 5,
#                     title: "LU - Unavailable",
#                     start: '2017-10-20T08:00:00',
#                     end: '2017-10-20T09:00:00',
#                     className: "booked"
#                 },
#                 {
#                     id: 10,
#                     title: "BR - Pfizer",
#                     start: '2017-10-20T10:00:00',
#                     end: '2017-10-20T11:00:00',
#                     className: "confirmed"
#                 }
#             ]
#         }
# }