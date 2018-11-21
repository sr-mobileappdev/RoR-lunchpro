class Templates::UserTemplate < Templates::BaseTemplate
  attr_reader :user

  def initialize(obj = nil)
    @object_type = obj.class
    @user = obj
  end

  def tags
    {
      email_address: 'email',
      first_name: 'first_name',
      last_name: 'last_name',
      full_name: 'display_name',
      space: 'user_space',
      invite_token: 'invite_token',
      accept_invite_url: 'accept_invite_url',
      reset_password_url: 'reset_password_url',
      confirmation_url: "confirmation_url",
      email: "email",
      non_lp_orders_for_tomorrow: "non_lp_orders_for_tomorrow",
      update_notification_preferences_url: "update_notification_preferences_url",
      phone_number: "primary_phone",
      deleted_entity_type: "deleted_entity_type",
      deleted_entity_name: 'deleted_entity_name',
      deleted_entity_phone_number: 'deleted_entity_phone_number',
      deleted_entity_email_address: 'deleted_entity_email_address'
    }
  end

  def __primary_phone
    ApplicationController.helpers.format_phone_number_string(@user.primary_phone)
  end

  def __user_space
    @user.display_space
  end

  def __invite_token
    @user.invitation_token
  end

  def __deleted_entity_type
    if @@options && @@options['entity'].present?
      @@options['entity']['type']
    end
  end

  def __deleted_entity_name
    if @@options && @@options['entity'].present?
      @@options['entity']['name']
    end
  end

  def __deleted_entity_phone_number
    if @@options && @@options['entity'].present?
      @@options['entity']['phone_number']
    end
  end

  def __deleted_entity_email_address
    if @@options && @@options['entity'].present?
      @@options['entity']['email_address']
    end
  end

  def __update_notification_preferences_url
    if @user.space == "space_sales_rep"
      UrlHelpers.rep_profile_index_url(tab: "notifications")
    elsif @user.space == "space_office"
      UrlHelpers.notification_preferences_office_preferences_url
    elsif @user.space == "space_restaurant"
      UrlHelpers.restaurant_account_index_url(tab: "contact_information")
    end
  end

  def __confirmation_url
    if @@notification_event_id.to_s == '209' && @@options && @@options['user_id'].to_i == @user.id.to_i
      UrlHelpers.user_confirmation_url(confirmation_token: @user.send(:generate_confirmation_token))
    end    
  end

  def __reset_password_url
    if @@notification_event_id.to_s == '418' && @@options && @@options['user_id'].to_i == @user.id.to_i
      UrlHelpers.edit_user_password_url(:reset_password_token => @user.send(:set_reset_password_token))
    end
  end

  def __accept_invite_url
    if ['412', '413', '100'].include?(@@notification_event_id.to_s)
      @user.skip_invitation = true
      @user.invite!(@current_user) do |u|
        u.skip_invitation = true
      end
      resp = UrlHelpers.accept_user_invitation_url(:invitation_token => @user.raw_invitation_token)
      @user.update(:invitation_sent_at => Time.now)
      resp
    end
  end

  def __non_lp_orders_for_tomorrow
    if @user.space_admin?
      ac = ActionController::Base.new()
      ah = ApplicationController.helpers
      orders = Order.non_lp_orders_for_tomorrow
      ##should style table in email content and render <trs> in partial
      table = ac.render_to_string(partial: 'shared/notification_partials/non_lp_orders', :layout => false, locals:{orders: orders, ah: ah}, :formats => [:html])
      table.html_safe
    end
  end

  # Custom getters
  # def __total_amount_cents
  #
  # end

end
