class Forms::RestaurantManagers::RestaurantContact
  attr_writer :params, :restaurant
  attr_reader :errors, :restaurant

  def initialize(restaurant, params = {})
    @restaurant = restaurant
    @params = params
    @errors = []
  end

  def valid?
    if @params[:restaurant_pocs_attributes].present?
      return (@errors.count == 0) unless validate_restaurant_pocs
    end

    @restaurant.assign_attributes(@params)

    return (@errors.count == 0)
  end

  def validate_restaurant_pocs
    pocs = @params[:restaurant_pocs_attributes]

    if pocs.select{|key, poc| poc["status"] == 'active' && poc["primary"] == '1'}.keys.count < 1
      @errors << "There must be at least one primary contact at all times. Please choose a new primary before deleting your current one"
      return false
    else
      return true
    end

  end

  def save_restaurant_pocs

    @params[:restaurant_pocs_attributes].each do |key, poc|
      if poc[:id]
        upt_poc = RestaurantPoc.find(poc[:id])
        upt_poc.assign_attributes(poc)
        unless upt_poc.valid? && upt_poc.save
          @errors += upt_poc.errors.full_messages
        end
      else
        @restaurant.restaurant_pocs.create(poc)
      end
    end

    return (@errors.count == 0)
  end

  def check_primary_contacts?
    unless @restaurant.primary_contacts.where(status != 'deleted') < 1
      @errors << "There must be at least one primary contact at all times. Please choose a new primary before deleting your current one"
    end
    return (@errors.count == 0)
  end

  def save
    if valid? && save_restaurant_pocs
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
