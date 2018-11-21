class Forms::AdminRestaurantPoc < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :restarant_poc

  def initialize(user, params = {}, existing_restaurant_poc = nil)
    @current_user = user
    @params = params
    @errors = []

    @restaurant_poc = existing_restaurant_poc
  end

  def valid?

    raise "Missing required parameters (:restaurant_poc)" unless @params[:restaurant_poc]

    # Validate Sales Rep
    @restaurant_poc ||= RestaurantPoc.new()
    @restaurant_poc.assign_attributes(@params[:restaurant_poc])


    unless @restaurant_poc.valid?
      @errors += @restaurant_poc.errors.full_messages
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

  def save_and_invite
    if valid? && persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @restaurant_poc.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
