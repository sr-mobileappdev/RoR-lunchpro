class Admin::UsersController < AdminTableController
  before_action :set_record, only: [:show, :edit, :update, :reinvite, :deactivate, :activate, :impersonate, :password, :update_password]

  # -- Enable Search
  before_action :enable_search, only: [:index, :office, :restaurant]

  def set_search
    @for = params[:for] if params[:for].present?
    @available_scopes = [{scope: 'active', title: 'Active Users'}, {scope: 'inactive', title: 'Deactivated Users'}]
    klass = "User"
    @search_path = search_admin_users_path
    super(klass, @for)
  end
  # --

  def set_record
    @record = User.find(params[:id])
  end


  def preferences

  end
  
  def password
    
  end
  
  def update_password
  	@record.assign_attributes(admin_update_password_params)
  	@record.assign_attributes(:invitation_accepted_at => Time.now.utc, :confirmed_at => Time.now.utc, :invitation_token => nil)
  	if !@record.save
  		render :json => { success: false, general_error: 'Unable to reset password due to the following errors or notices:', errors: @record.errors.full_messages }, :status => 500
  	else
	  	redirect_to admin_user_path(:id => @record.id)
  	end
  end

  
  # -- Scope Table
  def scope_table
    default_columns = ['id','display_name','email','display_space']

    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = User.none

    # -- Search stuff
    if params[:search_id]
      @search = UserSearch.where(id: params[:search_id]).first
    end
    # --
    #
    # -- Filter / Scope Stuff
    @scope = nil
    scope_params = []
    for_space = nil
    if params[:scope].present?
      @scope = params[:scope]
      scope_params = User.scope_params_for([@scope])
    end
    if params[:for].present?
      scope_params = scope_params.merge({"space" => "space_#{params[:for]}"})
      
    else
      controller_action = request.referrer.split('/').last.split('?').first
      case controller_action

      when 'office'
        scope_params = scope_params.merge({"space" => 'space_office'})
      when 'restaurant'
        scope_params = scope_params.merge({"space" => 'space_restaurant'})
      else
        
      end
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page)
    else
      @manager = Managers::AdminTableManager.new(User, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page)
    end

  end


  def get_table_path(params)
    if params[:for].present?
      case params[:for]

      when 'office'
        office_admin_users_path(params.except(:for))
      when 'restaurant'
        restaurant_admin_users_path(params.except(:for))
      else
        admin_users_path(params)
      end
    else
      controller_action = request.referrer.split('/').last.split('?').first
      case controller_action

      when 'office'
        office_admin_users_path(params)
      when 'restaurant'
        restaurant_admin_users_path(params)
      else
        admin_users_path(params)
      end
    end

  end
  # --

  def index
    @available_scopes = [{scope: 'active', title: 'Active Users'}, {scope: 'inactive', title: 'Deactivated Users'}]
  end

  def office
    @available_scopes = [{scope: 'active', title: 'Active Users'}, {scope: 'inactive', title: 'Deactivated Users'}]
  end

  def restaurant
    @available_scopes = [{scope: 'active', title: 'Active Users'}, {scope: 'inactive', title: 'Deactivated Users'}]
  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_users_path(search_id: search_id)
    @for = params[:for] if params[:for].present?
    if @for
      render action: @for
    else
      render action: :index
    end
  end

  def new
    @record = User.new(:space => 'space_admin')
  end

  def create
    # Run temporary validation first, before inviting user
    user = User.new(user_params)
    if !validate(user)
      render :json => {success: false, general_error: "Unable to create new user due to the following errors:", errors: user.errors.full_messages}, status: 500
      return
    end

    @user = User.invite!(user_params) do |u|
      u.skip_invitation = false
      u.skip_confirmation!
    end
    if params[:user][:space] == 'space_sales_rep'
      existing_reps = SalesRep.match_email_phone_name(params[:user][:email], params[:user][:primary_phone],  @user.first_name,  @user.last_name)
      if existing_reps.any?
        @user.sales_rep = existing_reps.first
      end
    end  
    Managers::NotificationManager.send_invite!(@user, current_user)

    flash[:notice] = "User has been created, and an invite email has been sent to #{user.email}."
    render :json => {success: true, redirect: admin_users_path }
    return

  end

  def update

    unless @record.update(user_params)
      render :json => {success: false, general_error: "Unable to update user due to the following errors:", errors: @record.errors.full_messages}, status: 500
      return
    end

    flash[:notice] = "User has been updated."
    render :json => {success: true, redirect: admin_user_path(@record) }
    return

  end

  def reinvite

    notice_or_alert = {}
    if @record.space == 'space_office'          
      if Managers::NotificationManager.trigger_notifications([412], [@record, @record.user_office.office])        
        notice_or_alert = {notice: "Invitation email has been resent to: #{@record.email}"}
      else
        notice_or_alert = {alert: "Unable to send invitation email to #{@record.email} as this email address doesn't appear to exist"}
      end
    elsif @record.space == 'space_restaurant'
      if Managers::NotificationManager.trigger_notifications([413], [@record, @record.user_restaurant.restaurant])
        notice_or_alert = {notice: "Invitation email has been resent to: #{@record.email}"}
      else
        notice_or_alert = {alert: "Unable to send invitation email to #{@record.email} as this email address doesn't appear to exist"}
      end
    else
      if Managers::NotificationManager.trigger_notifications([100], [@record, @record.sales_rep])
        notice_or_alert = {notice: "Invitation email has been resent to: #{@record.email}"}
      else
        notice_or_alert = {alert: "Unable to send invitation email to #{@record.email} as this email address doesn't appear to exist"}
      end
    end

    redirect_to admin_user_path(@record), notice_or_alert

  end

  # Test path for actioncable ping tests
  def ping
    Managers::ActioncableManager.new("internal_notice", "admin_notifications_#{current_user.id}").broadcast({ message: 'Actioncable ping test was successful assuming you can see and read this message in the admin.' })
    head :ok
  end

  # Test path for testing / faking background tasks from the frontend in development -- These will be run synchonously
  def rake
    unless Rails.env.development?
      head :ok
      return
    end

    task = params[:task]

    case task
      when "process_notifications"
        # Take from tasks / cron.rb `process_notifications` method
        default_processing_user = User.where(email: 'michael.q.carr@gmail.com').first
        if default_processing_user
          Managers::NotificationManager.process_new(5.minutes, default_processing_user)
        end
      when "process_notifications_now"
        # A slight modification of tasks / cron.rb `process_notifications` method
        default_processing_user = User.where(email: 'michael.q.carr@gmail.com').first
        if default_processing_user
          Managers::NotificationManager.process_new(5.seconds, default_processing_user)
        end
      else
        task = "No Task"
    end

    render html: "<p><strong>Background Process Finished</strong><br/>Finished running <pre>#{task}</pre></p>".html_safe and return

  end

  def activate
    form = Forms::User.new(@record, {}, current_user)
    unless form.reactivate_account
      flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
      render :json => {success: true, redirect: admin_user_path(@record) } and return
    end

    flash[:notice] = "User has been activated within the LunchPro system."
    render :json => {success: true, redirect: admin_user_path(@record) } and return

  end

  def deactivate
    prior_status = @record.status

    form = Forms::User.new(@record, current_user)
    unless form.delete_account
      flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
      render :json => {success: true, redirect: admin_user_path(@record) } and return
    end

    flash[:alert] = "User has been deactivated within the LunchPro system."
    render :json => {success: true, redirect: admin_user_path(@record) } and return

  end


private

  def validate(user)
    user.password = "temporary_for_validation123"
    if user.valid?
      true
    else
      false
    end
  end

  def user_params
    params.fetch(:user, {}).permit!
  end
  
  def admin_update_password_params
  	params.require(:user).permit(:password, :password_confirmation)
  end

end
