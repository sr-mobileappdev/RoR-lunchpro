class Api::V1::NotificationsController < ApiController

  before_action :set_record, only: [:destroy]
  
  def set_record
  	@notification = Notification.find(params[:id])
  end

  def index
  	records = []
  	if params[:sales_rep_id].present?
  		sales_rep = SalesRep.find(params[:sales_rep_id])
  		if sales_rep.user.present? && sales_rep.user.active?
  			notifications = sales_rep.user.visible_notifications
  			notifications.each do |notif|
  				records << notif.as_json(:except => ["title"]).merge({ title: notif.web_title(notif.user.notification_recipient_type), category_id: notif.notification_event.category_cid })
  			end
  		end
  	end
  	
  	render json: records and return
  end
  
  def destroy
    @notification.read_at ||= Time.now
    @notification.removed_at = Time.now

    @notification.save!
    
    render json: { success: true } and return
  end
end
