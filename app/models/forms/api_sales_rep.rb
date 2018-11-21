class Forms::ApiSalesRep < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :sales_rep
  attr_reader :user
  attr_reader :company

  def initialize(params = {}, company = nil, existing_sales_rep = nil)
    @params = params
    @errors = []

    @sales_rep = existing_sales_rep
    @company = company
  end

  def save(send_activation = false)
  	if !@params[:first_name].present? || !@params[:last_name].present? || !@params[:email].present? || !@params[:primary_phone].present? || !@params[:sales_rep_phone].present?
  		@errors << "First name, last name, email, primary phone, and sales rep (business) phone are all required for registration"
  		return false
  	end
    ActiveRecord::Base.transaction do
    
    	if !@sales_rep.present?
    		@sales_rep = SalesRep.new()
    	end

      @sales_rep.assign_attributes(@params.select {|k,v| ["first_name", "last_name", "company_id", "address_line1", "address_line2", "city", "state", "postal_code"].include?(k) })
      @user = (@sales_rep.user) ? @sales_rep.user : User.new
      @user.assign_attributes((@params.select {|k,v| ["first_name", "last_name", "email", "password", "password_confirmation", "primary_phone"].include?(k) }).merge({space: 'space_sales_rep'}))
      @user.skip_invitation
      @user.skip_confirmation_notification!
      if @user.save
        @sales_rep.user_id = @user.id
        @sales_rep.company_id ||= (@company) ? @company.id : nil
        if @sales_rep.save
          if @sales_rep.company && @company
            @company.update_attributes(created_by_id: @user.id)
          end
          
          phone = nil
          if !@sales_rep.sales_rep_phones.any?
          	phone = SalesRepPhone.new(:sales_rep_id => @sales_rep.id, :phone_number => @params[:sales_rep_phone], :phone_type => SalesRepPhone.phone_types[:business], :status => SalesRepPhone.statuses.key(Constants::STATUS_ACTIVE))
          else
          	phone = @sales_rep.sales_rep_phones.first
          	phone.assign_attributes(:phone_number => @params[:sales_rep_phone])
          end
          unless phone.save
          		@errors += phone.errors.full_messages
          		raise ActiveRecord::Rollback
          end
          
          email = nil
          if !@sales_rep.sales_rep_emails.any?
          	email = SalesRepEmail.new(:sales_rep_id => @sales_rep.id, :email_address => @params[:email], :email_type => SalesRepEmail.email_types[:business], :status => SalesRepEmail.statuses.key(Constants::STATUS_ACTIVE))
          else
          	email = @sales_rep.sales_rep_emails.first
          	email.assign_attributes(:email_address => @params[:email])
          end
          unless email.save
          		@errors += email.errors.full_messages
          		raise ActiveRecord::Rollback
          end
          
          enable_default_notifications
          return true
        else
          @errors += @sales_rep.errors.full_messages
          raise ActiveRecord::Rollback
        end
      else
        @errors += @user.errors.full_messages
        raise ActiveRecord::Rollback
      end
    end

    return (@errors.count == 0)
  end


private

  def delivery_invite!
    @user.invite!(@current_user) do |u|
      u.skip_invitation = true
    end

    Managers::NotificationManager.send_invite!(@user, @current_user)
  end

  def enable_default_notifications
  	return unless @user && @user.id
  	user_prefs = UserNotificationPref.new(:status => 'active', :user_id => @user.id, :last_updated_by_id => @user.id,
      :via_email => User.default_rep_notifications(true), :via_sms => User.default_rep_notifications(false))
    return user_prefs.save!
  end

  def persist!
    ActiveRecord::Base.transaction do
      if @sales_rep.save && @user.save
        @sales_rep.update_attributes(user_id: @user.id)
        enable_default_notifications
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
