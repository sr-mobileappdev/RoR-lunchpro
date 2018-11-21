class Forms::RestaurantManagers::RestaurantAvailability
  attr_writer :params, :restaurant
  attr_reader :errors, :restaurant


  def initialize(restaurant, params = {})
    @restaurant = restaurant
    @params = params
    @errors = []
    @new_record = false
  end


  def valid?
    if @params[:restaurant_availabilities_attributes].present?
      return (@errors.count == 0) unless validate_restaurant_availabilities
    end
    @restaurant.assign_attributes(@params)
    unless @restaurant.valid?
      @errors += @restaurant.errors.full_messages
    end
    return (@errors.count == 0)
  end

  def validate_restaurant_availabilities
    avails = @params[:restaurant_availabilities_attributes]

    avails.select{|key, avail| avail["status"] != 'inactive'}.each do |key, avail|
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
    if persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @restaurant.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end

end
