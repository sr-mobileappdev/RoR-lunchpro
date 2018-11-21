class Forms::AdminUserOffice < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :user_office
  attr_reader :user

  def initialize(user, params = {}, existing_user_office = nil, existing_user = nil)
    @current_user = user
    @params = params
    @errors = []

    @user_office = existing_user_office
    @user = existing_user
  end

  def valid?

    raise "Missing required parameters (:user_office)" unless @params[:user_office]
    raise "Missing required parameters (:user)" unless @params[:user]

    # Validate Sales Rep
    @user_office ||= UserOffice.new()
    @user_office.assign_attributes(@params[:user_office])


    unless @user_office.valid?
      @errors += @user_office.errors.full_messages
    end

    # Validate User
    @user ||= User.new(space: 'space_office')
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
    if valid? && persist! && delivery_invite!
      true
    else
      false
    end
  end

private

  def delivery_invite!
    #@user.invite!(@current_user) do |u|
     # u.skip_invitation = false
    #end
    Managers::NotificationManager.trigger_notifications([412], [@user, @user_office.office])
    #Managers::NotificationManager.send_invite!(@user, @current_user)
  end

  def enable_default_notifications
    return unless @user && @user.id
    prefs = UserNotificationPref.create!(:status => 'active', :user_id => @user.id, :last_updated_by_id => @current_user.id,
      :via_email => User.default_office_notifications(true))
    #prefs.reset_to_default!
  end

  def persist!
    ActiveRecord::Base.transaction do
      if @user_office.save && @user.save

        @user.skip_invitation = true
        @user_office.update_attributes(user_id: @user.id)
        enable_default_notifications
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
