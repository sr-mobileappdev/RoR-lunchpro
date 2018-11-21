class Api::Frontend::OrdersController < ApplicationController

  before_action :authenticate_user!

  def index
    @user = current_user
    @slots = []
    @consolidated = session[:hq_consolidated_view]
    time_range = Time.zone.now.to_date.beginning_of_week..Time.zone.now.to_date.end_of_week

    if params[:start_date].present? && params[:end_date].present?
      begin
        if Date.parse(params[:end_date]) > Time.now.to_date
          time_range = Date.parse(params[:start_date])..Time.now.to_date
        else
          time_range = Date.parse(params[:start_date])..Date.parse(params[:end_date])
        end
      rescue Exception => ex
      end
    end

    if @user.space_sales_rep?
      serializable_resource = { sales_rep: SalesRepsSerializer.new(@user.sales_rep)}
      manager = Views::SalesRepAppointments.new(@user.sales_rep, time_range, nil)
      @slots = manager.past_events(1)
    end

    if @user.space_restaurant?
      restaurant = Restaurant.find(params[:restaurant])
      serializable_resource = { restaurant: RestaurantsSerializer.new(restaurant)}
      manager = Views::RestaurantOrders.new(restaurant, time_range, @consolidated)
      @slots = manager.past_events(1)
    end

    serializable_resource = {}
    render json: { status: 'success' }.merge(serializable_resource).merge({ data: { events: @slots }}) and return

  end
end