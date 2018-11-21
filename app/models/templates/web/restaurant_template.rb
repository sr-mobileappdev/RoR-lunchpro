class Templates::Web::RestaurantTemplate < Templates::BaseTemplate
  attr_reader :restaurant

  def initialize(obj = nil)
    @object_type = obj.class
    @restaurant = obj
  end

  def tags
    return [] if !@restaurant
    {
      name: "name",
      postal_code: 'postal_code'
    }
  end
end
