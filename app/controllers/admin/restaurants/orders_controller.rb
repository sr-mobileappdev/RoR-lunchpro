class Admin::Restaurants::OrdersController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update, :confirm, :cancel]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_record
    @record = Order.find(params[:id])
  end

  def index

  end

  def show

  end

  def confirm
    unless @record.appointment.confirm_for_restaurant!
      render json: {success: false, general_error: "Unable to confirm this order at this time due to a server error", errors: []}, status: 500
    end

    flash[:notice] = "Order Number '#{@record.order_number}' has been confirmed"
    redirect_to admin_restaurant_orders_path
  end

  def cancel
    @record.restaurant_cancelled = true      #virtual attr to bypass order notif triggers
    @record.update_attributes(status: 'inactive')
    @record.appointment.update_attributes(restaurant_confirmed_at: nil)

    Managers::NotificationManager.trigger_notifications([301],
      [@restaurant, @record, @record.appointment, @record.appointment.office], {poc: current_user.poc_info})

    flash[:alert] = "Order has been declined"
    redirect_to admin_restaurant_orders_path
  end

end
