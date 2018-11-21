class OrdersSerializer < ActiveModel::Serializer

  def attributes(attrs, unknown_param = nil)
    data = super(attrs)

    fields = [:id, :order_number, :restaurant]
    if scope
      fields = scope.map &:to_sym
    end

    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end

  def restaurant
    if object.restaurant
      RestaurantsSerializer.new(object.sales_rep).serializable_hash
    else
      nil
    end
  end

end
