class PasswordsController < Devise::PasswordsController
  prepend_before_action :require_no_authentication, except: [:create]
  def new
    super
  end
  #overriding reset password functionality
  def create
    user = User.where(:email => resource_params[:email]).first
    if user.present?
      #for now... if user is an admin.. just send the email immediately, no notification
      if !user.entity
        super
        return
      else
        Managers::NotificationManager.trigger_notifications([418], [user, user.entity])
      end
    else
      flash[:notice] = "You must provide a valid email."
      redirect_to new_password_path(resource_class) and return
    end
    if params[:admin_reset]
      notice_or_alert = {notice: "This User Will Receive An Email With Instructions On How To Reset Their Password In A Few Minutes."}
      redirect_to request.referrer, notice_or_alert and return
    else
      flash[:notice] = "You Will Receive An Email With Instructions On How To Reset Your Password In A Few Minutes."
      redirect_to new_session_path(resource_class) and return
    end
  end

  def edit
    super
  end

  def update
    super
  end
end