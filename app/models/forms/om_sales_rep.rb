class Forms::OmSalesRep < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :sales_rep
  attr_reader :user

  def initialize(user, params = {}, office = nil, appointment_form = nil)
    @current_user = user
    @params = params
    @errors = []
    @office = office
    @appointment_form = appointment_form

    @sales_rep = nil
    @user = nil
    @phone = nil
    @email = nil
  end

  def valid?

    
    raise "Missing required parameters (:sales_rep)" unless @params[:sales_rep] && @office
    

    existing_reps = SalesRep.match_email_phone_name(@params[:sales_rep][:email_address], @params[:sales_rep][:phone_number],
     @params[:sales_rep][:first_name], @params[:sales_rep][:last_name])

    @sales_rep = nil
    @user = nil
    if existing_reps.any? && existing_reps.first.non_lp
      @sales_rep = existing_reps.first
    end
    
    # Validate Sales Rep
    if !@sales_rep.present?
      @sales_rep = SalesRep.new()
    end
    @sales_rep.assign_attributes(@params[:sales_rep])

    if @params[:sales_rep][:phone_number].present?
      if !@sales_rep.sales_rep_phones.any?
        @sales_rep.sales_rep_phones << SalesRepPhone.new(:phone_number => @params[:sales_rep][:phone_number], :status => 'active', :phone_type => "business", 
          :created_by_id => @current_user.id)
      else
        @sales_rep.sales_rep_phones.first.assign_attributes(:phone_number => @params[:sales_rep][:phone_number])
      end
    end
    
    if @params[:sales_rep][:email_address].present?
      if !@sales_rep.sales_rep_emails.any?
          @sales_rep.sales_rep_emails << SalesRepEmail.new(:status => 'active', :email_type => 'business', :email_address => @params[:sales_rep][:email_address], 
            :created_by_id => @current_user.id)
      else
        @sales_rep.sales_rep_emails.first.assign_attributes(:email_address => @params[:sales_rep][:email_address])
      end
    end
  
    if !@sales_rep.company.present?
      if @params[:sales_rep][:company_id].present?
          @company = Company.new(:name => @params[:sales_rep][:company_id])
        end
    end
    unless @sales_rep.valid?
      @errors += @sales_rep.errors[:base] + @sales_rep.errors[:'user.base']
    end

    # Validate User
=begin    @user ||= User.new(space: 'space_sales_rep', first_name: @sales_rep.first_name, last_name: @sales_rep.last_name, :email => @params[:sales_rep][:email_address])

    if @user.new_record?
      @user.password = "temporary_for_validation123" unless @user.password.present?
    end

    unless @user.valid?
      @errors += @user.errors.full_messages
    end
=end
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
    if valid? && persist! && set_company
      #delivery_invite!
      true
    else
      false
    end
  end

  def create_email_record
    if @params[:sales_rep][:email_address].present?
      @business_email = SalesRepEmail.find_or_initialize_by(:sales_rep_id => @sales_rep.id, :email_type => "business")
      @business_email.assign_attributes({:created_by_id => @current_user.id, :email_address => @params[:sales_rep][:email_address], :status => 'active', :email_type => "business"})
      unless @business_email.save
        @errors += @sales_rep.errors.full_messages
      end
    else
      @errors << "You must provide a business email."
      return
    end

    return (@errors.count == 0)
  end

  def create_phone_record
    if @params[:sales_rep][:phone_number].present?
      @phone = SalesRepPhone.find_or_initialize_by(:sales_rep_id => @sales_rep.id)
      #default value is business, and reps can only manipulate their business phone
      @phone.assign_attributes({:created_by_id => @current_user.id, :phone_number => @params[:sales_rep][:phone_number], :status => 'active', :phone_type => "business"})
      unless @phone.save
        @errors += @sales_rep.errors.full_messages
      end
    else
      @errors << "You must provide a phone number."
      return
    end

    return (@errors.count == 0)
  end

  def create_offices_sales_rep_record    
    @offices_sales_rep = OfficesSalesRep.new(:sales_rep_id => @sales_rep.id, :status => 'active', :office_id => @office.id, :created_by_id => @current_user.id)
    unless @offices_sales_rep.save
      @errors += @sales_rep.errors.full_messages
    end


    return (@errors.count == 0)
  end

  def create_appointment
    if @appointment_form
      @appointment_form.appointment.sales_rep_id = @sales_rep.id
      if @appointment_form.valid? && @appointment_form.save
        true
      else
        @errors << @appointment_form.errors
        false
      end
    else
      true
    end
  end

  def set_company
    if @company.present? && @company.new_record?
      existing_comp = Company.select{|comp| comp.active? && comp.name.downcase == @company.name.downcase}.first
      if existing_comp
        @company = existing_comp
      else
        @company.assign_attributes(:created_by_id => @current_user.id, :status => 'active')
        @company.save!
      end
      @sales_rep.company = @company
      @sales_rep.save!
      true
    end
    true
  end
private

  def delivery_invite!
    @user.invite!(@current_user) do |u|
      u.skip_invitation = false
    end

    Managers::NotificationManager.send_invite!(@user, @current_user)
  end

  def enable_default_notifications
    return unless @user && @user.id
    prefs = UserNotificationPref.create!(user_id: @user.id, notifiable: nil, status: 'active')
    prefs.reset_to_default!
  end

  def persist!
    ActiveRecord::Base.transaction do
      if @sales_rep.save && create_offices_sales_rep_record && create_appointment
        #@sales_rep.update_attributes(user_id: @user.id)
        #enable_default_notifications
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
