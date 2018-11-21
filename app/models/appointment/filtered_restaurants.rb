class Appointment::FilteredRestaurants
  attr_reader :office
  attr_reader :restaurants
  attr_writer :filters

  DEFAULT_PRICE_RANGE = 12

  def initialize(office, filters = {}, appointment = nil, current_user = nil, impersonator = false)
    @office = office
    @restaurants = []
    @filters = filters
    @appointment = appointment
    @current_user = current_user
    @impersonator = impersonator
  end

  def filtered
    raise "Must provide appointment and current_user to filter" if !@appointment || !@office
    restaurant_ids = @office.filtered_available_restaurants(@appointment, @current_user, @impersonator)

    relation = Restaurant.includes(:cuisines).includes(orders: [:order_reviews]).where(id: restaurant_ids)
    if @filters && @filters[:price_range].present?
      range = @filters[:price_range].first || DEFAULT_PRICE_RANGE
      relation = relation.where(person_price_low: (0..range.to_i)).uniq
    end

    if @filters && @filters[:cuisines].present? && !@filters[:price_range].present?
      relation = relation.select{|r| (@filters[:cuisines].map{|c| c.to_i} - r.cuisines.pluck(:id)).empty?}
    end

    if @filters && @filters[:cuisines].present? && @filters[:price_range].present?
      relation = relation.select {|item| !(item.cuisines.pluck(:id) & @filters[:cuisines].map(&:to_i)).empty? }
    end

    relation
  end

end
