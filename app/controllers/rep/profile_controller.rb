class Rep::ProfileController < ApplicationRepsController

  before_action :set_rep
  before_action :set_user, only: [:change_password, :update_password]

  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end


  def set_rep
    @sales_rep = current_user.sales_rep
  end

  def set_user
    @user = current_user
  end
  def index
    #if tab param is passed in, display tab on load
    @show_tab = params[:tab] || "summary"
    @record_id = params[:id]
  end


  def end_impersonation
    impersonator = User.where(:id => session[:impersonator_id]).first
    return if !impersonator
    sign_in(:user, impersonator)
    redirect_to session[:impersonator_return_url]
  end

  def update_password
    form = Forms::User.new(@user, user_params, current_user)

    unless form.change_password?
      render :json => {success: false, general_error: "Unable to update sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end    
    sign_in(current_user, :bypass => true)
    Managers::NotificationManager.trigger_notifications([212], [@sales_rep])        
    # Model validations & save
    flash[:success] = "Password Changed successfully!"
    redirect_to rep_profile_index_path(tab: 'summary')
    return

  end

  def update
    tab = params[:for]
    if tab == "financial_info"
      form = Forms::FrontendSalesRep.new(@sales_rep, allowed_params, params[:for])
      unless form.valid?
        render :json => {success: false, general_error: "Unable to update sales rep due to the following errors or notices:", errors: form.errors}, status: 500
        return
      end
      unless form.save
        render :json => {success: false, general_error: "Unable to update sales rep at this time to the following errors or notices:", errors: form.errors}, status: 500
        return
      end
    elsif tab == "summary"
      form = Forms::FrontendSalesRep.new(@sales_rep, rep_params, params[:for])
      unless form.save && form.update_drugs(params[:sales_rep_drugs])
        render :json => {success: false, general_error: "Unable to update sales rep due to the following errors or notices:", errors: form.errors}, status: 500
        return
      end
    elsif tab == "rewards"
      form = Forms::FrontendSalesRep.new(@sales_rep, allowed_params, params[:for])
      unless form.save
        render :json => {success: false, general_error: "Unable to update sales rep at this time to the following errors or notices:", errors: form.errors}, status: 500
        return
      end
    end
    # Model validations & save

    flash[:success] = "Sales Rep was updated successfully!"
    if tab.present?
      redirect_to rep_profile_index_path(tab: tab)
    else
      redirect_to rep_profile_index_path(tab: "summary")
    end

  end

  def create

  end

  def summary
    @companies = Company.active.select(:id, :name).to_json
    @drugs = Drug.active.select(:id, :brand).to_json
    @sales_rep_drugs = @sales_rep.drugs.map(&:drug_id).join ','
    @sales_rep.sales_rep_emails.build(:email_type => 'personal', :status => 'active', :created_by_id => @modifier_id) if !@sales_rep.email_exists?("personal")
    @sales_rep.sales_rep_emails.build(:email_type => 'business', :status => 'active', :created_by_id => @modifier_id) if !@sales_rep.email_exists?("business")
    @sales_rep.sales_rep_phones.build(:phone_type => 'personal', :status => 'active', :created_by_id => @modifier_id) if !@sales_rep.phone_exists?("personal")
    @sales_rep.sales_rep_phones.build(:phone_type => 'business', :status => 'active', :created_by_id => @modifier_id) if !@sales_rep.phone_exists?("business")
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_summary', :layout => false, :formats => [:html])
      }
    }
  end

  def financial_info
    @offices_sales_reps = @sales_rep.offices_sales_reps.active
    @payment_methods = current_user.non_default_payment_methods
    @default_payment_method = current_user.default_payment_method
    if !@payment_methods
      @record = PaymentMethod.new
      @payment_manager = Managers::PaymentManager.new(@sales_rep.user, nil, @record)
    end
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_financial_info', :layout => false, :formats => [:html])
      }
    }
  end


  def partner
    #@new_partners = @sales_rep.eligible_partners_selectize
    @partner_request = SalesRepPartner.new(:sales_rep_id => @sales_rep.id)
    @partners = @sales_rep.sales_rep_partners.accepted
    @pending_partners = @sales_rep.pending_partners
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_partners', :layout => false, :formats => [:html])
      }
    }
  end

  def notifications
    @user_notification_prefs = current_user.user_notification_prefs.active.first
    if !@user_notification_prefs
      @user_notification_prefs = UserNotificationPref.new(:user_id => @modifier_id, :status => 'active', 
        :last_updated_by_id => @modifier_id, :via_email => {}, :via_sms => {})
    end
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_notifications', :layout => false, :formats => [:html])
      }
    }
  end

  def update_notification_prefs
    
    user_notification_prefs = current_user.user_notification_prefs.active.first
    if !user_notification_prefs.present?
      user_notification_prefs = UserNotificationPref.new(allowed_notification_prefs_params)
    else
      user_notification_prefs.assign_attributes(allowed_notification_prefs_params)
    end
    user_notification_prefs.save!


    flash[:success] = "Notification Preferences have been updated!"
    redirect_to rep_profile_index_path(tab: "notifications")
  end

  def rewards

    @sales_rep.sales_rep_emails.build(:email_type => 'personal', :status => 'active', :created_by_id => @modifier_id) if !@sales_rep.email_exists?("personal")
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_rewards', :layout => false, :formats => [:html])
      }
    }
  end
  
  def faq
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_faq', :layout => false, :formats => [:html])
      }
    }
  end
  
  def general_information
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_terms', :layout => false, :formats => [:html])
      }
    }
  end

  def change_password

    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__detail_change_password', :layout => false, :formats => [:html])
      }
    }
  end

  def office_budgets
    render json: {
      templates: {
        targ__rep_profile: (render_to_string :partial => 'rep/profile/components/profile__office_budgets_form', :layout => false, :formats => [:html])
      }
    }
  end

  def update_office
    record = OfficesSalesRep.find(params[:offices_sales_rep][:id])
    if params[:budget]
      params[:offices_sales_rep][:per_person_budget_cents] = params[:offices_sales_rep][:per_person_budget_cents].to_f
      params[:offices_sales_rep][:per_person_budget_cents] *= 100
      record.update_attributes!(allowed_office_params)
      flash[:success] = "Office has been updated!"
      redirect_to controller: 'offices', action: 'index', id: record.office_id, tab: 'about' and return
    end
    if params[:notes]
      record.update_attributes!(allowed_office_params)
      flash[:success] = "Office has been updated!"
      redirect_to controller: 'offices', action: 'index', id: record.office_id, tab: 'notes' and return
    end
  end

  def update_budgets
    form = Forms::OfficesSalesRep.new(current_user, nil, current_user.sales_rep, allowed_params)
    unless form.update_budgets
      render :json => {success: false, general_error: "Unable to update office budgets due to the following:", errors: form.errors}, status: 500
      return
    end
    flash[:success] = "Sales Rep was updated successfully!"
    redirect_to rep_profile_index_path(tab: "financial_info")
  end
  

  def show_delete_account
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/rep_delete', :layout => false, :formats => [:html]) }
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    else
      get_my_offices
      render :index
    end
  end

  def delete_account
    form = Forms::User.new(current_user, current_user)
    unless form.delete_account
      flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
    end
    flash[:success] = "Account was successfully deactivated!"
    sign_out current_user
    redirect_to new_session_path('user')
  end

  def show_contact_us
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/contact_us', :layout => false, :formats => [:html]) }
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    else
      get_my_offices
      render :index
    end
  end

  def upload_asset
    @record = @sales_rep
    if @xhr
      render json: { html: (render_to_string :partial => 'shared/modals/uploader_popup', locals: {upload_path: complete_upload_asset_rep_profile_path(@record), upload_param: :profile_image}, :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  def complete_upload_asset
    if params[:sales_rep].present?
      image_from_client = parse_image_data(params[:image_data])
      @sales_rep.update_attributes(:profile_image => image_from_client)

      clean_tempfile
      
      flash[:success] = "Profile Picture has been uploaded!"
    else
      flash[:error] = "You must select an image to upload"
    end    
    redirect_to rep_profile_index_path(tab: "summary")
  end


  private

  def parse_image_data(base64_image)
    filename = "profile-image"
    in_content_type, encoding, string = base64_image.split(/[:;,]/)[1..3]

    @tempfile = Tempfile.new(filename)
    temp_file_path = @tempfile.path
    @tempfile.binmode
    @tempfile.write Base64.decode64(string)
    @tempfile.rewind

    content_type = params[:image_file_type]
    # we will also add the extension ourselves based on the above
    # if it's not gif/jpeg/png, it will fail the validation in the upload model
    extension = content_type.match(/gif|jpeg|png/).to_s
    filename += ".#{extension}" if extension
    ActionDispatch::Http::UploadedFile.new({
      tempfile: @tempfile,
      content_type: content_type,
      filename: filename
    })    
  end
  
  def clean_tempfile
    if @tempfile
      @tempfile.close
      @tempfile.unlink
    end
  end

  def rep_params
    params.require(:sales_rep).permit(:specialties, :per_person_budget_cents, :first_name, :last_name, :company_id, :default_tip_percent, :max_tip_amount_cents, :company_name,
      sales_rep_emails_attributes: [:email_type, :created_by_id, :status, :id, :email_address], 
      user_attributes: [:primary_phone, :id], sales_rep_phones_attributes: [:phone_type, :created_by_id, :status, :phone_number, :id])
  end

  def allowed_params
    groupings = [:sales_rep, :offices_sales_rep, :offices_sales_reps, :sales_rep_emails_attributes, :user_attributes]
    super(groupings, params)
  end

  def test_params
    #params.require(:sales_rep).permit!
    test = params[:sales_rep][:offices_sales_reps]
    groupings = [test]
    super(groupings, params)
  end
  def allowed_notification_prefs_params
    params.require(:user_notification_pref).permit(:user_id, :status, :last_updated_by_id, via_email: {}, via_sms: {})
  end
  def user_params
    params.require(:user).permit(:current_password, :password, :password_confirmation)
  end

  def allowed_office_params
    params.require(:offices_sales_rep).permit(:notes, :per_person_budget_cents)
  end

  def allowed_upload_params
    params.require(:sales_rep).permit(:profile_image)
  end

end
