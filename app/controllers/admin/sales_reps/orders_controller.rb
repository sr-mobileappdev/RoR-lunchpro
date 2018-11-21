class Admin::SalesReps::OrdersController < AdminController
  before_action :set_parent_record

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end


  def index

  end

  def send_receipt

  end


private



end
