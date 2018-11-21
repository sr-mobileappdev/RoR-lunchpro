class ApplicationNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notification_worker"
  end
end

