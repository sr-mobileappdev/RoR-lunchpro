class Admin::DrugsController < AdminTableController

  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :delete]

  # -- Enable Search
  before_action :enable_search, only: [:index]

  def set_search

    @available_scopes = [{scope: 'active', title: 'Active Drugs'}, {scope: 'inactive', title: 'Deactivated Drugs'}]
    klass = "Drug"
    @search_path = search_admin_drugs_path
    super(klass)
  end
  # --

  def set_record
    @record = Drug.find(params[:id])
  end

  # -- Scope Table
  def scope_table
    default_columns = ['id','brand']
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = Drug.none

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
      scope_params = Drug.scope_params_for([@scope])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page)
    else
      @manager = Managers::AdminTableManager.new(Drug, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page)
    end

  end

  def get_table_path(params)
    admin_drugs_path(params)
  end
  # --

  def index

    @available_scopes = [{scope: 'active', title: 'Active Drugs'}, {scope: 'inactive', title: 'Deactivated Drugs'}]

  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_drugs_path(search_id: search_id)

    render :index
  end

  def new
    @record = Drug.new(created_by_id: current_user.id)
  end

  def create

    form = Forms::AdminDrug.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new drug due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new drug at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Drug has been created."
    render :json => {success: true, redirect: admin_drugs_path }
    return

  end

  def update

    form = Forms::AdminDrug.new(current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update drug due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update drug at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Drug has been updated."
    render :json => {success: true, redirect: admin_drugs_path }
    return

  end

  def delete
    prior_status = @record.status
    @record.deleted!

    flash[:alert] = "Drug has been removed from the system. This will only appear in historical reports, where applicable."
    render :json => {success: true, redirect: admin_drugs_path() }
  end

private

  def allowed_params
    groupings = [:drug]

    super(groupings, params)
  end

end
