class Forms::AdminRestaurant < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :restaurant

  def initialize(user, params = {}, existing_restaurant = nil)
    @current_user = user
    @params = params
    @errors = []

    @restaurant = existing_restaurant

    if @params[:restaurant_cuisines].present?
      @params[:restaurant_cuisines] = @params[:restaurant_cuisines].split(",")
    end
  end

  def valid?
    raise "Missing required parameters (:restaurant)" unless @params[:restaurant]

    # Validate Restaurant
    @restaurant ||= Restaurant.new()
    @restaurant.assign_attributes(@params[:restaurant])
    if @restaurant.new_record?
      @restaurant.assign_attributes(withhold_tax: true, max_order_people: 1000, processing_fee_percent: 300)
    end

    hq_id = @params[:restaurant][:headquarters_id]

    if @params[:restaurant_cuisines].present?
      @restaurant.cuisines = []
      @params[:restaurant_cuisines].each do |name|
        if name.present?
          @restaurant.cuisines << Cuisine.find_by(name: name)
        end
      end
    end

    if @params[:delivery_distance] && @params[:delivery_distance].kind_of?(ActionController::Parameters)
      @restaurant.delivery_distance ||= DeliveryDistance.new(@params[:delivery_distance])

      if @params[:trig__radius] && @params[:trig__radius] == "advanced"
        @restaurant.delivery_distance.use_complex = true
      elsif @params[:trig__radius] && @params[:trig__radius] == "basic"
        @restaurant.delivery_distance.use_complex = false
      end

      @restaurant.delivery_distance.assign_attributes(@params[:delivery_distance])
    end

    unless @restaurant.delivery_distance && @restaurant.delivery_distance.valid?
      @errors += @restaurant.delivery_distance.errors.full_messages
    end

    if @params[:restaurant][:restaurant_availabilities_attributes] && @params[:restaurant][:restaurant_availabilities_attributes].kind_of?(ActionController::Parameters)
      return (@errors.count == 0) unless validate_restaurant_availabilities
    end

    unless @restaurant.valid?
      @errors += @restaurant.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def validate_restaurant_availabilities
    avails = @params[:restaurant][:restaurant_availabilities_attributes]

    avails.select{|key, avail| avail["status"] != 'inactive' && avail['starts_at'].present? && avail['ends_at'].present?}.each do |key, avail|
      avail = avail.to_hash
      timerange = Tod::TimeOfDay(avail['starts_at'])..Tod::TimeOfDay(avail['ends_at'])
      if avails.select{|key, av| av["day_of_week"] == avail["day_of_week"] && av["_destroy"] != 'true' && av["status"] != 'deleted' && (timerange).cover?(Tod::TimeOfDay(av.to_hash['starts_at']) ||
        (timerange).cover?(Tod::TimeOfDay(av.to_hash['ends_at'])))}.to_hash.count > 1
        @errors << "You cannot provide overlapping availabilities."
        return false
      end
    end
  end

  def save
    if valid? && persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @restaurant.save
        if @params[:delivery_distance].present? && @restaurant.delivery_distance.save
          return true
        else
          return true
        end
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
