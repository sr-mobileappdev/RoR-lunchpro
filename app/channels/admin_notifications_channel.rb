class AdminNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "admin_notifications_#{current_user.id}"
  end
end
