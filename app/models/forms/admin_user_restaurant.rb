class Forms::AdminUserRestaurant < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :user_restaurant
  attr_reader :user

  def initialize(user, params = {}, existing_user_restaurant = nil, existing_user = nil)
    @current_user = user
    @params = params
    @errors = []

    @user_restaurant = existing_user_restaurant
    @user = existing_user
  end

  def valid?

    raise "Missing required parameters (:user_restaurant)" unless @params[:user_restaurant]
    raise "Missing required parameters (:user)" unless @params[:user]

    # Validate Sales Rep
    @user_restaurant ||= UserRestaurant.new()
    @user_restaurant.assign_attributes(@params[:user_restaurant])


    unless @user_restaurant.valid?
      @errors += @user_restaurant.errors.full_messages
    end

    # Validate User
    @user ||= User.new(space: 'space_restaurant')
    @user.assign_attributes(@params[:user])

    if @user.new_record?
      @user.password = "temporary_for_validation123" unless @user.password.present?
    end
    
    @user.skip_confirmation!  
    @user.skip_invitation = true
    unless @user.valid?
      @errors += @user.errors.full_messages
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
      delivery_invite!
      true
    else
      false
    end
  end

private

  def delivery_invite!
    Managers::NotificationManager.trigger_notifications([413], [@user, @user_restaurant.restaurant])
  end

  def enable_default_notifications
    return unless @user && @user.id
    prefs = UserNotificationPref.create!(:status => 'active', :user_id => @user.id, :last_updated_by_id => @current_user.id,
      :via_email => User.default_restaurant_notifications(true), :via_sms => User.default_restaurant_notifications(false))
  end

  def persist!
    ActiveRecord::Base.transaction do
      if @user_restaurant.save && @user.save
        @user_restaurant.update_attributes(user_id: @user.id)
        enable_default_notifications
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
