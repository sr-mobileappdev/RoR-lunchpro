class Restaurant::OrdersController < ApplicationRestaurantsController
  before_action :set_restaurant_user
  before_action :set_restaurant
  before_action :set_order, only: [:index, :detail, :download]
  before_action :set_past_order, only: [:history, :download]
  after_action :set_past_order, only: [:history]

  def set_restaurant_user
    @restaurant_user = UserRestaurant.find_by(user_id: current_user.id)
    @consolidated = session[:hq_consolidated_view]
  end

  def set_restaurant
    @restaurant = Restaurant.find((current_restaurant_id || @restaurant_user.restaurant_id))
  end

  def set_order
    if params[:id]
      @order = Order.where(:id => params[:id]).first.id
    elsif params[:format]
      @order = Order.where(:id => params[:format]).first.id
    else
      if @consolidated
        @unconfirmed_orders = @restaurant.consolidated_unconfirmed_orders
        @confirmed_orders = @restaurant.consolidated_confirmed_orders
        if @unconfirmed_orders.any?
          @order = @unconfirmed_orders.first.id
        elsif @confirmed_orders.any?
          @order = @confirmed_orders.first.id
        else
        end
      else
        @unconfirmed_orders = @restaurant.unconfirmed_orders
        @confirmed_orders = @restaurant.confirmed_orders
        if @unconfirmed_orders.any?
          @order = @unconfirmed_orders.first.id
        elsif @confirmed_orders.any?
          @order = @confirmed_orders.first.id
        else
        end
      end
    end

    if @order.present?
      if @consolidated
        unless (@restaurant.child_restaurants.pluck(:id) << @restaurant.id).include? Order.find(@order).restaurant_id
          redirect_to "/404" and return
        end
      else
        unless Order.find(@order).belongs_to?(@restaurant)
          redirect_to "/404" and return
        end
      end
    end
  end

  def set_past_order
    if params[:id]
      @order = Order.find(params[:id])
    end

    if @order.present?
      unless Order.find(@order.id).belongs_to?(@restaurant)
        redirect_to "/404" and return
      end
    end
  end

  def index

  end

  def history
    @time_range = Time.now.beginning_of_month..Time.now.to_date
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
      template: (render_to_string :partial => "restaurant/orders/components/past_orders",
      locals: {slot_manager: Views::RestaurantOrders.new(@restaurant, time_range, @consolidated)}, :layout => false, :formats => [:html])
    }
  end

  def detail
    @edit = params[:edit]

    @order = Order.find(@order)
    if @order && @order.appointment.cancelled_at
      user = User.find(@order.appointment.cancelled_by_id)
      if user.display_space == "office"
        @cancelled_by = "office"
      elsif user.display_space == "Sales rep"
        @cancelled_by = "sales rep"
      end
    end
  end

  def driver_info
    @order = Order.find(params[:id])
    if @xhr
      if modal?
        render :json => { html: (render_to_string partial: 'shared/modals/restaurants/driver_info', layout: false, formats: [:html]) }
        return
      else
        raise "Opening modal view without passing is_modal=true"
      end
    end
  end

  def show
    @order = Order.find(params[:id])

      if @order.completed?
        render json: { templates: {
                        targ__restaurant_order_detail: (render_to_string partial: "restaurant/orders/components/past_order_detail", layout: false, formats: [:html])
                      }
                    }
      else
        render json: { templates: {
                        targ__restaurant_order_detail: (render_to_string partial: "restaurant/orders/components/order_detail", layout: false, formats: [:html])
                      }
                    }
      end

  end

  def update_confirmation
    @order = Order.find(params[:id])
    if params[:confirm]
      @order.appointment.confirm_for_restaurant!
      flash[:success] = "Order has been confirmed"
      if current_user
        return_path = restaurant_orders_path(id: @order.id)
      else
        return_path = new_user_session_path
      end
      redirect_to return_path
    else
      # decline order - set status to rejected? deleted?
      if @order.restaurant_cancellable?
        @order.restaurant_cancelled = true      #virtual attr to bypass order notif triggers
        @order.update_attributes(status: 'inactive', cancelled_at: Time.now, cancelled_by_id: current_user.id)
        @order.appointment.update_attributes(restaurant_confirmed_at: nil)

        Managers::NotificationManager.trigger_notifications([301],
          [@restaurant, @order, @order.appointment, @order.appointment.office], {poc: current_user.poc_info})

        flash[:alert] = "Order has been declined"
        redirect_to restaurant_orders_path
      else
        flash[:alert] = "Order cannot be cancelled within 4 hours of the delivery time"
        redirect_to restaurant_orders_path
      end
    end

  end

  def update_driver
    @order = Order.find(params[:id])
    if order_params[:driver_name].present? && order_params[:driver_phone].present? && @order.update_attributes(order_params)
      flash[:success] = "Delivery Driver information has been updated"

      redirect_to restaurant_orders_path(id: @order.id)
    else
      @restaurant.errors.add(:base, "A name and phone number must be entered for the delivery driver")
      render json: { success: false, general_error: "This order could not be updated due to the following reasons:", errors: @restaurant.errors.full_messages}, status: 500
    end

  end

  def download
    respond_to do |format|
      format.csv do
        man = Managers::CsvManager.new
        csv_data = man.generate_order_detail(@order)
        unless !man.errors.any?
          flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
          redirect_to rep_orders_path(order: @order.id) and return
        end
        send_data csv_data,
              :type => 'text/csv',
              :disposition => "attachment; filename=Order_#{@order.order_number}.csv"
      end
      format.pdf do
        if @order
          @rep_order_review = @order.active_review('SalesRep')
          @office_order_review = @order.active_review('Office')
          appointment = Appointment.find(params[:current_appointment_id]) if params[:current_appointment_id].present?
        end
        ah = ApplicationController.helpers
        pdf = WickedPdf.new.pdf_from_string(
          render_to_string(partial: 'shared/pdf/restaurant_order_detail', :layout => 'pdf', locals:{order: @order, ah: ah}, :formats => [:html]))
        send_data pdf, filename: "Order_#{@order.order_number}.pdf", type: "application/pdf", :disposition => 'inline'
      end
    end
  end


  def print
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(partial: 'shared/pdfs/restaurant_order_detail', :layout => 'pdf', locals:{order: @order}, :formats => [:html]))
=begin
    tempfile = Tempfile.new(["#{@modifier_id}_#{@order.order_number}_#{Time.now.to_i}", ".pdf"], Rails.root.join('tmp'))
    tempfile.binmode
    tempfile.write pdf
    tempfile.close

    system("lpr", tempfile.path)
    tempfile.unlink

    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(partial: 'shared/pdfs/rep_om_order_detail', :layout => 'pdf', locals:{order: @order}, :formats => [:html]))
    system("lpr", "pdfs/filename.pdf")
=end
  end

private

  def order_params
    params.require(:order).permit(:status, :driver_name, :driver_phone, appointments_attributes: [:id, :restaurant_confirmed_at])
  end

end
