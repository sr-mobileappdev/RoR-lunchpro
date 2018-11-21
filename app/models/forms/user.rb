class Forms::User < Forms::Form
  attr_writer :params
  attr_reader :errors
  attr_reader :user
  attr_reader :sales_rep

  def initialize(user, params = {}, current_user)
    @params = params
    @errors = []
    @user = user
    @current_user = current_user

  end

  def valid_for_registration?

    raise "Missing required parameters (:user)" unless @params
    # Validate Sales Rep
    
    existing_reps = SalesRep.match_email_phone_name(@params[:email], @params[:sales_rep_attributes][:phone_number], @params[:first_name], @params[:last_name])
    @sales_rep = nil
    @user = nil
    if existing_reps.any? && existing_reps.first.non_lp
      @sales_rep = existing_reps.first
      if @sales_rep.user.present?
        @user = @sales_rep.user
      end
    end
    
    if !@user.present?
      @user = User.new()
    end
    
    @user.assign_attributes(@params.except(:sales_rep_attributes))    
    @user.primary_phone = @params[:sales_rep_attributes][:phone_number]
    @user.space = 'space_sales_rep'
    unless @user.valid?
        @user.errors.delete(:'sales_rep.base')
        @user.errors.delete(:'sales_rep.user.email')
        @errors += @user.errors.full_messages
        return (@errors.count == 0)
    end
    
    if !@sales_rep.present?
      @sales_rep = SalesRep.new()
    end
    @sales_rep.assign_attributes(@params[:sales_rep_attributes])    
    @sales_rep.assign_attributes(:first_name => @user.first_name, :last_name => @user.last_name, :timezone => Constants::DEFAULT_TIMEZONE)
    if @params[:sales_rep_attributes][:company_id].present?
      @sales_rep.assign_attributes(:company_id => @params[:sales_rep_attributes][:company_id])
    end
    
    if !@sales_rep.sales_rep_phones.any?
      @sales_rep.sales_rep_phones << SalesRepPhone.new(:phone_number => @params[:sales_rep_attributes][:phone_number], :status => 'active', :phone_type => "business", :created_by_id => @user.id)
    else
    	@sales_rep.sales_rep_phones.first.assign_attributes(:phone_number => @params[:sales_rep_attributes][:phone_number])
    end
    
    if !@sales_rep.sales_rep_emails.any?
        @sales_rep.sales_rep_emails << SalesRepEmail.new(:status => 'active', :email_type => 'business', :email_address => @params[:email], :created_by_id => @user.id)
    else
    	@sales_rep.sales_rep_emails.first.assign_attributes(:email_address => @params[:email])
    end
  
    if !@sales_rep.company.present?
      if @params[:sales_rep_attributes][:company_id].present?
        @company = Company.new(:name => @params[:sales_rep_attributes][:company_id])
      end
    end


    unless @sales_rep.valid?
        @errors += @sales_rep.errors.messages[:base]
    end  
      
    return (@errors.count == 0)
  end

  def change_password?
    current_password = @params.delete(:current_password)
    if @user.valid_password?(current_password)

      if @user.update_attributes(@params)
      else
       @errors << @user.errors.full_messages
      end
    else
      @errors << "Current password does not match"
    end
    return (@errors.count == 0)
  end


  def set_company
    if @company.present? && @company.new_record?
      existing_comp = Company.select{|comp| comp.active? && comp.name.downcase == @company.name.downcase}.first
      if existing_comp
        @company = existing_comp
      else
        @company.assign_attributes(:created_by_id => @user.id, :status => 'active')
        @company.save!
      end
      @sales_rep.company = @company
      true
    end
    true
  end

  def create_notification_prefs
    user_prefs = UserNotificationPref.new(:status => 'active', :user_id => @user.id, :last_updated_by_id => @user.id,
      :via_email => User.default_rep_notifications(true), :via_sms => User.default_rep_notifications(false))
    return user_prefs.save!
  end

  def queue_notification
    Managers::NotificationManager.trigger_notifications([209], [@sales_rep, @sales_rep.user])
  end

  def delete_account
    ActiveRecord::Base.transaction do
      begin
        if user.entity && user.entity.kind_of?(SalesRep)
          rep = user.entity
          rep.upcoming_appointments.each do |appt|
            appt.update(:cancelled_at => Time.now, :cancelled_by_id => @user.id, :status => 'inactive')
            appt.orders.active.each do |order|
              order.update(:status => 'inactive')
              order.line_items.update_all(:status => 'deleted')
            end
          end
          rep.offices_sales_reps.update_all(:status => "deleted")
          rep.update(:status => 'inactive', :deactivated_at => Time.now)
        elsif user.entity && user.entity.kind_of?(Office)
          user.user_office.update(:status => 'inactive')
        elsif user.entity && user.entity.kind_of?(Restaurant)
          user.user_restaurant.update(:status => 'inactive')
        end
        user.update(:status => 'inactive', :deactivated_at => Time.now, :deactivated_by_id => @current_user.id)
      rescue => ex
        Rollbard.error(ex)
        raise ActiveRecord::Rollback
        return false
      end
    end
    true
  end

  def reactivate_account
    ActiveRecord::Base.transaction do
      begin
        rep =  SalesRep.where(:user_id => user.id, :status => 'inactive').first
        if rep          
          rep.update(:status => 'active', :activated_at => Time.now, :deactivated_at => nil)
        elsif user.entity && user.entity.kind_of?(Office)
         
        elsif user.entity && user.entity.kind_of?(Restaurant)

        end
      rescue => ex
        Rollbard.error(ex)
        raise ActiveRecord::Rollback
        return false
      end      
      user.update(:status => 'active', :deactivated_at => nil, :deactivated_by_id => nil)
    end
    true
  end

  def register_rep
    ActiveRecord::Base.transaction do
      @user.skip_invitation
      @user.skip_confirmation_notification!
      unless @sales_rep.valid?
        @errors += @sales_rep.errors.full_messages
        raise ActiveRecord::Rollback
      end
      if @user.save! && (@user.sales_rep = @sales_rep) && create_notification_prefs && set_company && queue_notification
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
  
  def save
    if valid? && persist!
      true
    else
      false
    end
  end

  
private

end
