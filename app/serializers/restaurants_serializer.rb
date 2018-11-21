class RestaurantsSerializer < ActiveModel::Serializer

  def attributes(attrs, unknown_param = nil)
    data = super(attrs)

    fields = [:id, :name]
    if scope
      fields = scope.map &:to_sym
    end

    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end

end
