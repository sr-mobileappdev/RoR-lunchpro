class Forms::FrontendRestaurant < Forms::Form
  attr_writer :params
  attr_reader :errors

  attr_reader :restaurant

  def initialize(restaurant, params = {}, tab = nil)
    @params = params
    @errors = []
    @tab = tab
    @restaurant = restaurant
    @user = params[:user]
    @phone = nil
    @email = nil
  end

  def valid?
    raise "Missing required parameters (:restaurant)" unless @params[:restaurant]
    # Validate Sales Rep
    @restaurant ||= Restaurant.new()
    @restaurant.assign_attributes(@params[:restaurant])
    unless @restaurant.valid?
      @errors += @restaurant.errors.full_messages
    end
    return (@errors.count == 0)
  end

  def update_phone(phone = nil)
    if phone.present?
      if restaurant.phone_valid?
        @phone = @restaurant.phone
      else
        @errors << "You must provide a 10 digit phone number."
      end
    else
      @errors << "You must provide a phone number."
      return
    end
    return (@errors.count == 0)
  end

  def save
    if valid? && persist!
      true
    else
      false
    end
  end

  def cancel

  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @tab == 'summary' && @restaurant.save
        return true
      elsif @tab != 'summary' && @restaurant.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
