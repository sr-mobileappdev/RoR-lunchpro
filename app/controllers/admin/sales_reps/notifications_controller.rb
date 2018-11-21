class Admin::SalesReps::NotificationsController < AdminController
  before_action :set_parent_record

  def set_parent_record
    @rep = SalesRep.find(params[:sales_rep_id])
  end

  
  def index
  	@rep_notifs = @rep.notifications
  end

end
