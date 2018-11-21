class Admin::SalesReps::RewardsController < AdminController
  before_action :set_parent_record

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  def show

  end

  def new

  end

  def create

  end

private

end
