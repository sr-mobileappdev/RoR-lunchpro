class Forms::AdminSalesRep < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors
  attr_reader :marked_for_registration

  attr_reader :sales_rep
  attr_reader :user

  def initialize(user, params = {}, existing_sales_rep = nil, existing_user = nil)
    @current_user = user
    @params = params[:sales_rep]
    @errors = []
    @marked_for_registration = false

    @sales_rep = existing_sales_rep
    @user = existing_user
  end

  def valid?

    raise "Missing required parameters (:sales_rep)" unless @params
    raise "Missing required parameters (:user_attributes)" unless @params[:user_attributes]
    if @params[:specialties].present?
      @params[:specialties] = @params[:specialties].split(",")
    end

    if !@user.present? || @user.new_record?
      @user = User.new(:password => "temporary_for_validation123")
      @marked_for_registration = true
    end

    @user.assign_attributes(@params[:user_attributes])  if @params[:user_attributes]
    @user.space = 'space_sales_rep'
    unless @user.valid?
        @user.errors.delete(:'sales_rep.base')
        @user.errors.delete(:'sales_rep.user.email')
        @user.errors.delete(:'sales_rep.user.base')
        @errors += @user.errors.full_messages
        return (@errors.count == 0)
    end

    if !@sales_rep.present?
      @sales_rep = SalesRep.new()
    end

    phones = @sales_rep.sales_rep_phones.where(:phone_type => 'business', :status => 'active')
    if phones.any?
      phones.update_all(:phone_number => @params[:user_attributes][:primary_phone])
    else
      @sales_rep.sales_rep_phones << SalesRepPhone.new(:phone_number => @params[:user_attributes][:primary_phone], :status => 'active',
        :phone_type => "business", :created_by_id => @current_user.id)
    end

    emails = @sales_rep.sales_rep_emails.where(:email_type => 'business', :status => 'active')
    if emails.any?
      emails.update_all(:email_address => @params[:user_attributes][:email])
    else
       @sales_rep.sales_rep_emails << SalesRepEmail.new(:status => 'active', :email_type => 'business', :email_address => @params[:user_attributes][:email], :created_by_id => @current_user.id)
    end
    @params = @params.except(:user_attributes)

    @sales_rep.assign_attributes(@params)
    @user.assign_attributes(:first_name => @sales_rep.first_name, :last_name => @sales_rep.last_name, :timezone => Constants::DEFAULT_TIMEZONE)
    if @params[:company_id].present?
      @sales_rep.assign_attributes(:company_id => @params[:company_id])
    end


    if !@sales_rep.company.present?
      if @params[:company_id].present?
          @company = Company.new(:name => @params[:company_id])
        end
    end

    @sales_rep.user = @user

    unless @sales_rep.valid?
      @errors += @sales_rep.errors.messages[:base]
    end

    return (@errors.count == 0)
  end

  def valid_for_registration?
    raise "Missing required parameters (:sales_rep)" unless @params
    raise "Missing required parameters (:user_attributes)" unless @params[:user_attributes]

    if @params[:specialties].present?
      @params[:specialties] = @params[:specialties].split(",")
    end
    # Validate Sales Rep
    existing_reps = SalesRep.match_email_phone_name(@params[:user_attributes][:email], @params[:user_attributes][:primary_phone],  @params[:first_name],  @params[:last_name])
    @sales_rep = nil
    @user = nil
    if existing_reps.any? && existing_reps.first.non_lp
      @sales_rep = existing_reps.first
      if @sales_rep.user.present?
        @user = @sales_rep.user
      end
    end

    if !@user.present?
      @user = User.new(:password => "temporary_for_validation123")
    end

    @user.assign_attributes(@params[:user_attributes])
    @user.space = 'space_sales_rep'
    unless @user.valid?
        @user.errors.delete(:'sales_rep.base')
        @user.errors.delete(:'sales_rep.user.email')
        @user.errors.delete(:'sales_rep.user.base')
        @errors += @user.errors.full_messages
        return (@errors.count == 0)
    end

    if !@sales_rep.present?
      @sales_rep = SalesRep.new()
    end

    phones = @sales_rep.sales_rep_phones.where(:phone_type => 'business', :status => 'active')
    if phones.any?
      phones.update_all(:status => 'deleted')
    else
      @sales_rep.sales_rep_phones << SalesRepPhone.new(:phone_number => @params[:user_attributes][:primary_phone], :status => 'active',
        :phone_type => "business", :created_by_id => @current_user.id)
    end

    emails = @sales_rep.sales_rep_emails.where(:email_type => 'business', :status => 'active')
    if emails.any?
      emails.update_all(:status => 'deleted')
    else
       @sales_rep.sales_rep_emails << SalesRepEmail.new(:status => 'active', :email_type => 'business', :email_address => @params[:user_attributes][:email], :created_by_id => @current_user.id)
    end
    @params = @params.except(:user_attributes)

    @sales_rep.assign_attributes(@params)
    @user.assign_attributes(:first_name => @sales_rep.first_name, :last_name => @sales_rep.last_name, :timezone => Constants::DEFAULT_TIMEZONE)
    if @params[:company_id].present?
      @sales_rep.assign_attributes(:company_id => @params[:company_id])
    end


    if !@sales_rep.company.present?
      if @params[:company_id].present?
          @company = Company.new(:name => @params[:company_id])
        end
    end

    @sales_rep.user = @user

    unless @sales_rep.valid?
      @errors += @sales_rep.errors.messages[:base]
    end

    return (@errors.count == 0)
  end

  #instead of refactoring i decided to create a separate method, for times sake
  def valid_for_appointment?
    raise "Missing required parameters (:sales_rep)" unless @params[:sales_rep]
    # Validate Sales Rep
    @params = @params[:sales_rep]
    existing_reps = SalesRep.match_email_phone_name(@params[:sales_rep_emails_attributes]['0'][:email_address],
      @params[:sales_rep_phones_attributes]['0'][:phone_number] ,@params[:first_name],@params[:last_name])
    @sales_rep = nil
    if existing_reps.any? && existing_reps.first.non_lp
      @sales_rep = existing_reps.first
    end


    if !@sales_rep.present?
      @sales_rep = SalesRep.new()
    end


    if @params[:sales_rep_phones_attributes]['0'][:phone_number].present?
      phones = @sales_rep.sales_rep_phones.where(:phone_type => 'business', :status => 'active')
      if phones.any?
        phones.update_all(:status => 'deleted')
      end
    else
      @params = @params.except(:sales_rep_phones_attributes)
    end

    if @params[:sales_rep_emails_attributes]['0'][:email_address].present?
      emails = @sales_rep.sales_rep_emails.where(:email_type => 'business', :status => 'active')
      if emails.any?
        emails.update_all(:status => 'deleted')
      end
    else
      @params = @params.except(:sales_rep_emails_attributes)
    end

    @sales_rep.assign_attributes(@params)
    if @params[:company_id].present?
      @sales_rep.assign_attributes(:company_id => @params[:company_id])
    end


    if !@sales_rep.company.present?
      if @params[:company_id].present?
          @company = Company.new(:name => @params[:company_id])
        end
    end

    unless @sales_rep.valid?
      @errors += @sales_rep.errors.messages[:base]
    end

    return (@errors.count == 0)
  end

  def save
    if valid? && persist! && set_company
      true
    else
      false
    end
  end

  def save_appointment
    if persist! && set_company
      true
    else
      false
    end
  end

  def save_and_invite
    if @user.new_record?
      @user.skip_invitation
      @user.skip_confirmation_notification!
      if persist! && delivery_invite!
        true
      else
        false
      end
    else
      if persist!
        true
      else
        false
      end
    end

  end

  def set_company
    if @company.present? && @company.new_record?
      @company.assign_attributes(:created_by_id => @current_user.id, :status => 'active')
      @company.save!
      @sales_rep.company = @company
      @sales_rep.save!
      true
    end
    true
  end

private

  def delivery_invite!

    #@user.invite!(@current_user) do |u|
    #  u.skip_invitation = false
    #end
    Managers::NotificationManager.trigger_notifications([100], [@user, @sales_rep])
  end

  def enable_default_notifications
    return unless @user && @user.id
    prefs = UserNotificationPref.create!(:status => 'active', :user_id => @user.id, :last_updated_by_id => @current_user.id,
      :via_email => User.default_rep_notifications(true), :via_sms => User.default_rep_notifications(false))
    #prefs.reset_to_default!
  end

  def persist!
    ActiveRecord::Base.transaction do
      if @sales_rep.save
        if @user
          return false if !@user.save
          @user.update_attributes(:confirmation_sent_at => nil, :confirmation_token => nil)
          @sales_rep.update_attributes(user_id: @user.id)
          enable_default_notifications
        end
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
