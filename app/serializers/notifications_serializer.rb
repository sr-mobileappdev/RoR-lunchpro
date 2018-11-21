class NotificationsSerializer < ActiveModel::Serializer

  def attributes(attrs, unknown_param = nil)
    data = super(attrs)

    fields = [:id, :notification_event_id, :title, :priority, :read_at, :removed_at, :created_at, :updated_at, :notified_at, :queued_at, :status_summary, :related_objects] 
    if scope
      fields = scope.map &:to_sym
    end

    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end

end
