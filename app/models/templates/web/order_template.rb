class Templates::Web::OrderTemplate < Templates::BaseTemplate
  attr_reader :order

  def initialize(obj = nil)
    @object_type = obj.class
    @order = obj
  end

  def tags
    return [] if !@order
    {
      order_number: 'order_number'
    }
  end

end
