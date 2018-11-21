class Admin::OfficesController < AdminTableController
  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :edit_office_exclude_dates]

  # -- Enable Search
  before_action :enable_search, only: [:index]

  def set_search
    @available_scopes = [{scope: 'active', title: 'Active Offices'}, {scope: 'active internal', title: 'Non-LP Offices'}, {scope: 'inactive', title: 'Deactivated Offices'}]
    klass = "Office"
    @search_path = search_admin_offices_path
    super(klass)
  end
  # --

  def set_record
    @record = Office.find(params[:id])
  end

  def edit
    #building creates an empty diet_restrictions_office object and appends to end of array, which will be used in view
    @record.diet_restrictions_offices.build
  end

  def show
    @manager = @record.manager
  end

  # -- Scope Table
  def scope_table
    default_columns = ['id','lunchpad_status__light','name','calendar_open_until','phone','city']

    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = Office.none

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
      scope_params = Office.scope_params_for([@scope])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page, "name")
      @records = @records.sort_by{|r| r.name}
    else
      @manager = Managers::AdminTableManager.new(Office, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page, nil, "name")
    end

  end#scope_table


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
        csv_data = man.generate_active_offices(current_user)
        filename = "admin_active_offices"
      when 'inactive'
        csv_data = man.generate_inactive_offices(current_user)
        filename = "admin_inactive_offices"
    end
    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data,
      :type => 'text/csv',
      :disposition => "attachment; filename=#{filename}_#{Time.now.to_date}.csv"
  end

  def get_table_path(params)
    admin_offices_path(params)
  end
  # --

  def index
    @available_scopes = [{scope: 'active', title: 'Active Offices'}, {scope: 'active internal', title: 'Non-LP Offices'}, {scope: 'inactive', title: 'Deactivated Offices'}]
    @scope = params[:scope]
  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_offices_path(search_id: search_id)

    render :index
  end

  def new
    @record = Office.new(created_by_id: current_user.id, timezone: Constants::DEFAULT_TIMEZONE)
    @record.diet_restrictions_offices.build.build_diet_restriction
  end

  def create

    form = Forms::AdminOffice.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new office at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Office has been created."
    render :json => {success: true, redirect: admin_office_path(form.office) }
    return

  end

  def update

    form = Forms::AdminOffice.new(current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update office due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update office at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Office has been updated."
    redirect_to = params[:redirect_to] if params[:redirect_to].present?
    redirect_to = admin_office_path(form.office) if !redirect_to

    render :json => {success: true, redirect: redirect_to }
    return

  end

  def delete
    @record.deleted!

    flash[:alert] = "Office has been removed from the system. They will only appear in historical reports, where applicable."
    render :json => {success: true, redirect: admin_offices_path() }
  end

  def activate
    unless @record.can_activate?
      flash[:alert] = "Office cannot yet be activated due to the noted missing activation requirements."
      render :json => {success: true, redirect: admin_office_path(@record) }
      return
    end


    form = Forms::AdminOffice.new(current_user, {}, @record)
    unless form.activate
      flash[:alert] = "Office cannot be activated at this time due to the following error: " + @errors.first
      return
    end  

    flash[:notice] = "Office has been activated within the LunchPro system. They can now receive appointments and be found via search by other providers."
    render :json => {success: true, redirect: admin_office_path(@record) }
  end

  def deactivate
    prior_status = @record.status
    @record.update_attributes(deactivated_at: Time.now, status: 'inactive', deactivated_by_id: current_user.id)

    flash[:alert] = "Office has been deactivated within the LunchPro system. They will no longer be able to be found by sales reps in the LunchPro system unless the sales rep is already associated with this office."
    render :json => {success: true, redirect: admin_office_path(@record) }
  end


  #method called when opening office exclude date modal
  def edit_office_exclude_dates
      render json: { html: (render_to_string :partial => 'shared/modals/admin/offices/office_exclude_dates', locals: {}, :layout => false, :formats => [:html])}
      return
  end

private

  def allowed_params
    groupings = [:office]
    super(groupings, params)
  end
end
