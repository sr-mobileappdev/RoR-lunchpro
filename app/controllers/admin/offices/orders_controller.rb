class Admin::Offices::OrdersController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @office = Office.find(params[:office_id])
  end

  def set_record
    @record = Order.find(params[:id])
  end

  def index

  end

  def show

  end

  def edit
    set_step

    @appointment = @record.appointment
    @menu = (params[:menu_id].present?) ? Menu.find(params[:menu_id]) : nil

    if params[:restaurant_id].present?
      @restaurant = Restaurant.find(params[:restaurant_id])
      @record.restaurant_id = @restaurant.id
      @record.save
    end

    if @step == :select_restaurant

    elsif @step == :select_food

    else

    end

  end

  def new
    
  end


  def continue

      # @restaurant = Restaurant.find(params[:restaurant_id])
      # @record.restaurant_id = @restaurant.id
      # @record.save
      # redirect_to edit_admin_office_order_path(@record.appointment.office_id, @record.id, step: 2)

  end

private

  def appointment_params
    params.require(:appointment).permit!
  end

  def set_step
    @page_title = "Select a Nearby Restaurant"
    @step = :select_restaurant
    return unless params[:step]
    case params[:step]
      when "1"
        @step = :select_restaurant
      when "2"
        @step = :select_food
        @page_title = "Select Food Items"
      when "3"
        @step = :payment
        @page_title = "Payment Information"
      when "4"
        @step = :confirm
        @page_title = "Confirm Order"
    end
  end


end
