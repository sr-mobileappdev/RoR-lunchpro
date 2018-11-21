class Admin::Users::NotificationsController < AdminController
  before_action :set_record, only: [:show, :edit, :update]

  def index

  end

  def recent
    @notifications = current_user.admin_view.recent_notifications

    if @xhr
      render json: { html: (render_to_string :partial => 'admin/users/notifications/recent', :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end

  end

end
