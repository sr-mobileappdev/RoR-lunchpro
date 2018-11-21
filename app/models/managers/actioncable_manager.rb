class Managers::ActioncableManager
  attr_reader :broadcast_endpoint
  attr_writer :broadcast_type

  def initialize(broadcast_type = nil, broadcast = nil)
    @broadcast_type = broadcast_type
    if broadcast
      @broadcast_endpoint = broadcast
    end
  end

  def broadcast(details = nil) # broadcast right now
    return unless @broadcast_endpoint.present?
    
    if @broadcast_type == "internal_notice"
      c = ApplicationController.new # Temporarily using this to assist in rendering
      @message = details[:message]
      template_html = {html: (c.render_to_string :partial => 'admin/shared/components/internal_notice', locals: {message: @message}, :layout => false, :formats => [:html])}
     # ActionCable.server.broadcast @broadcast_endpoint, { broadcast_type: @broadcast_type, interval: 1000, details: details.merge(template_html) }
    elsif @broadcast_type == "notification_refresh"
     # ActionCable.server.broadcast @broadcast_endpoint, { broadcast_type: @broadcast_type, interval: 1000, details: details }
    elsif @broadcast_type == "app_notification_refresh"
      #ActionCable.server.broadcast @broadcast_endpoint, { broadcast_type: @broadcast_type}
    else
      #ActionCable.server.broadcast @broadcast_endpoint, { broadcast_type: @broadcast_type, interval: 1000, details: details }
    end
  end


  def broadcast_in(timeframe_from_now, details)

  end

end
