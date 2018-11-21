class Admin::Users::PreferencesController < AdminController

  before_action :set_record

  def set_record
    @record = User.find(params[:user_id])
  end

  def index

  end

  def recent

  end

  def edit_preferences
    @user_notification_prefs = @record.user_notification_prefs.active.first
    if !@user_notification_prefs
      @user_notification_prefs = UserNotificationPref.new(:user_id => @record.id, :status => 'active',
        :last_updated_by_id => current_user.id, :via_email => {}, :via_sms => {})
    end
  end

  def update_preferences
    user_notification_prefs = @record.user_notification_prefs.active.first
    if !user_notification_prefs.present?
      user_notification_prefs = UserNotificationPref.new(allowed_notification_prefs_params)
    else
      user_notification_prefs.assign_attributes(allowed_notification_prefs_params)
    end
    user_notification_prefs.save!


    flash[:success] = "Notification Preferences have been updated!"
    redirect_to admin_user_preferences_path(@record)
  end

private

  def allowed_notification_prefs_params
    params.require(:user_notification_pref).permit(:user_id, :status, :last_updated_by_id, via_email: {}, via_sms: {})
  end

end
