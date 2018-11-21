class Admin::Restaurants::PaymentsController < AdminController
  before_action :set_parent_record
  before_action :set_record, only: [:show, :edit, :update]

  def set_parent_record
    @restaurant = Restaurant.find(params[:restaurant_id])
  end

  def set_record
    @record = RestaurantTransaction.find(params[:id])
  end

  def index

  end

  def show

  end

end
