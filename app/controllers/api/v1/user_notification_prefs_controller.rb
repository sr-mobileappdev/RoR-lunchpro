class Api::V1::UserNotificationPrefsController < ApiController
  
  def create
  	sales_rep = SalesRep.find(params[:sales_rep_id])
  	email_event_ids = params[:notification_event_ids_for_email]
  	sms_event_ids = params[:notification_event_ids_for_sms]
  	
  	email_hash = { }
  	email_event_ids.each do |email_event_id|
  		email_hash[email_event_id] = "1"
  	end
  	
  	sms_hash = { }
  	sms_event_ids.each do |sms_event_id|
  		sms_hash[sms_event_id] = "1"
  	end
  	
  	mvc_style_params = { }
  	mvc_style_params[:via_email] = email_hash
  	mvc_style_params[:via_sms] = sms_hash
  	
  	user_notification_prefs = sales_rep.user.user_notification_prefs.active.first
    if !user_notification_prefs.present?
      	user_notification_prefs = UserNotificationPref.new(mvc_style_params)
      	user_notification_prefs.assign_attributes(:user_id => sales_rep.user_id, :last_updated_by_id => current_user.id, :status => 1)
    else
      	user_notification_prefs.assign_attributes(mvc_style_params)
      	user_notification_prefs.assign_attributes(:last_updated_by_id => current_user.id)
    end
    user_notification_prefs.save!
  end
  
  def index
  	record = nil
  	if params[:sales_rep_id].present?
  		sales_rep = SalesRep.find(params[:sales_rep_id])
  		record = UserNotificationPref.where(:user_id => sales_rep.user_id, :status => 1).first
  	end
  	render json: record.as_json(:except => ["via_email","via_sms"], :methods => ["notification_event_ids_for_email", "notification_event_ids_for_sms"]) and return
  end  
end