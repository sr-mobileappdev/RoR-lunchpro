class Rep::NotificationsController < ApplicationRepsController

  # -- Enable Search
  before_action :set_notification, except: [:index]

  def index
    if @xhr
      render json: {
        templates: {
          lp__notification_dropdown: (render_to_string :partial => 'shared/notification_partials/notification_dropdown', :layout => false, :formats => [:html])
        }
      }
    end
  end

  def remove
    @notification = Notification.find(params[:id])
    @notification.read_at ||= Time.now
    @notification.removed_at = Time.now

    @notification.save
    head :ok
  end

private

  def set_notification
    @notification = Notification.find(params[:id])
  end
end
