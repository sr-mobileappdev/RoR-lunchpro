class Admin::SalesRepsController < AdminTableController
  # NOTE: Routes file has path for this controller set to /reps/, for visual clarity

  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :delete, :reinvite]

  # -- Enable Search
  before_action :enable_search, only: [:index]

  def set_search
    @available_scopes = [{scope: 'active', title: 'Active Reps'}, {scope: 'inactive', title: 'Deactivated Reps'}]
    klass = "SalesRep"
    @search_path = search_admin_sales_reps_path
    super(klass)
  end
  # --

  def set_record
    @record = SalesRep.find(params[:id])
    @record.user ||= User.new()
  end

  def show

  end

  # -- Scope Table
  def scope_table
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    default_columns = ['id','first_name', 'last_name','display_location_single', 'is_lp?']
    @records = SalesRep.none

    # -- Search stuff
    if params[:search_id]
      @search = UserSearch.where(id: params[:search_id]).first
    end
    # --

    # -- Filter / Scope Stuff
    @scope = nil
    scope_params = []
    if params[:scope].present?
      @scope = params[:scope]
      scope_params = SalesRep.scope_params_for([@scope])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page)#@records = @manager.scoped.paged_results(@page, @per_page, "first_name, last_name")
    else
      @manager = Managers::AdminTableManager.new(SalesRep, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page)#@records = @manager.scoped.paged(@page, @per_page, nil, "first_name, last_name")
    end

  end#scope_table

  def get_table_path(params)
    admin_sales_reps_path(params)
  end
  # --

  def index

    @available_scopes = [{scope: 'active', title: 'Active Reps'}, {scope: 'inactive', title: 'Deactivated Reps'}]

  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_sales_reps_path(search_id: search_id)

    render :index
  end

  def new
    @record = SalesRep.new(created_by_id: current_user.id, timezone: Constants::DEFAULT_TIMEZONE)
    @record.user = User.new()
  end

  def edit
    @record.sales_rep_emails.build(:email_type => 'personal', :status => 'active', :created_by_id => current_user.id) if !@record.email_exists?("personal")
    @record.sales_rep_emails.build(:email_type => 'business', :status => 'active', :created_by_id => current_user.id) if !@record.email_exists?("business")
    @record.sales_rep_phones.build(:phone_type => 'personal', :status => 'active', :created_by_id => current_user.id) if !@record.phone_exists?("personal")
    @record.sales_rep_phones.build(:phone_type => 'business', :status => 'active', :created_by_id => current_user.id) if !@record.phone_exists?("business")
  end

  def report
    scope = params[:scope]
    if !scope.present?
      flash[:warning] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    man = Managers::CsvManager.new
    filename = ""

    case scope
      when 'active'
        csv_data = man.generate_active_reps(current_user)
        filename = "admin_active_reps"
      when 'inactive'
        csv_data = man.generate_inactive_reps(current_user)
        filename = "admin_inactive_reps"
      when 'lpReps'
        start_date = params[:start_date] || ((Date.today) + (Date.today.wday - 6) * -1) - 7
        end_date = params[:end_date] || Date.today.to_date
        csv_data = man.generate_active_lp_reps(current_user, start_date, end_date)
        filename = "admin_LP_reps"
      when 'nonLpReps'
        start_date = params[:start_date] || ((Date.today) + (Date.today.wday - 6) * -1) - 7
        end_date = params[:end_date] || Date.today.to_date
        csv_data = man.generate_active_non_lp_reps(current_user, start_date, end_date)
        filename = "admin_non_LP_reps"
    end

    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data,
      :type => 'text/csv',
      :disposition => "attachment; filename=#{filename}_#{Time.now.to_date}.csv"
  end


  def create
    form = Forms::AdminSalesRep.new(current_user, allowed_params)
    unless form.valid_for_registration?
      render :json => {success: false, general_error: "Unable to create new sales rep due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save_and_invite
      render :json => {success: false, general_error: "Unable to create new sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Sales rep has been created & invited to LunchPro."
    render :json => {success: true, redirect: admin_sales_rep_path(form.sales_rep) }
    return

  end

  def update
    form = Forms::AdminSalesRep.new(current_user, allowed_params, @record, @record.user)
    # Model validations & save
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update sales rep at this time due to a server error.", errors: form.errors}, status: 500
      return
    end

    unless form.save_and_invite
      render :json => {success: false, general_error: "Unable to create new sales rep at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Sales rep has been updated."
    render :json => {success: true, redirect: admin_sales_rep_path(form.sales_rep) }
    return

  end

  def reinvite

    notice_or_alert = {}
    if Managers::NotificationManager.trigger_notifications([100], [@record.user, @record])
      notice_or_alert = {notice: "Invitation email has been resent to: #{@record.email}"}
    else
      notice_or_alert = {alert: "Unable to send invitation email to #{@record.email} as this email address doesn't appear to exist"}
    end
    redirect_to admin_sales_rep_path(@record), notice_or_alert

  end

  def activate
    form = Forms::User.new(@record.user, {}, current_user)
    unless form.reactivate_account
      flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
      render :json => {success: true, redirect: admin_sales_rep_path(@record) } and return
    end

    flash[:notice] = "Sales rep has been activated within the LunchPro system. They can now place orders and schedule appointments on LunchPro offices."
    render :json => {success: true, redirect: admin_sales_rep_path(@record) }
  end

  def deactivate
    prior_status = @record.status

    form = Forms::User.new(@record.user, {}, current_user)
    unless form.delete_account
      flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
      render :json => {success: true, redirect: admin_sales_rep_path(@record) } and return
    end

    flash[:alert] = "Sales rep has been deactivated within the LunchPro system. They will no longer be able to place orders and schedule appointments on LunchPro offices."
    render :json => {success: true, redirect: admin_sales_rep_path(@record) } and return
  end

  def delete
    prior_status = @record.status
    @record.deleted!

    # Don't re-send if this user was previously deleted or de-activated
    if prior_status != "deleted" && prior_status != "deactivated"
      #Managers::NotificationManager.trigger_notifications([419], [@record], {}) # @record = sales rep
    end

    flash[:alert] = "Sales rep has been removed from the system. They will only appear in historical reports, where applicable."
    render :json => {success: true, redirect: admin_sales_reps_path() }
  end

private

  def allowed_params
    groupings = [:sales_rep, :user, :sales_rep_phones]

    allowed = {}
    groupings.each do |param_group|
      allowed[param_group] = params.fetch(param_group, {}).permit!

      allowed[param_group].select { |k, v| k.include?("_cents") }.each do |ar_k, val|
        allowed[param_group][ar_k] = val.to_f * 100
      end

      allowed[param_group].select { |k, v| k.include?("_percent") }.each do |ar_k, val|
        allowed[param_group][ar_k] = val.to_f * 100
      end

    end

    authed_params = ActionController::Parameters.new(allowed)
    authed_params
  end

  def rep_params
    params.require(:sales_rep).permit(:specialties, :per_person_budget_cents, :timezone, :first_name, :last_name, :company_id, :default_tip_percent, :max_tip_amount_cents, :company_name,
      :address_line1, :address_line2, :city, :state, :postal_code,
      sales_rep_emails_attributes: [:email_type, :created_by_id, :status, :id, :email_address],
      user_attributes: [:primary_phone, :id, :email], sales_rep_phones_attributes: [:phone_type, :created_by_id, :status, :phone_number, :id])
  end

end
