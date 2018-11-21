class Admin::Tools::MergeRepsController < AdminTableController

  before_action :enable_search, only: [:index]


  def merge
    unless params[:destination_id].present? && params[:source_id]
      render :json => {success: false, general_error: "Unable to merge reps due to the following issues:", errors: ['You must select both a source and destination record!']}, status: 500
      return
    end

    source_rep = SalesRep.where(:id => params[:source_id]).first
    destination_rep = SalesRep.where(:id => params[:destination_id]).first

    unless destination_rep && source_rep
      render :json => {success: false, general_error: "Unable to merge reps due to the following issues:", errors: ['You must select both a source and destination record!']}, status: 500
      return
    end

    man = Managers::MergeManager.new

    unless man.merge_reps(source_rep, destination_rep)
      render :json => {success: false, general_error: "Unable to merge reps due to the following issues:", errors: man.errors}, status: 500
      return
    end

    flash[:notice] = "Reps merged successfully!"
    render :json => {success: true, redirect: request.referrer}
  end

  def set_search
    @available_scopes = [{scope: 'active', title: 'Active Reps'}, {scope: 'inactive', title: 'Deactivated Reps'}]
    klass = "SalesRep"
    @search_path = search_admin_tools_merge_reps_path
    super(klass)
  end

    # -- Scope Table
  def scope_table
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    default_columns = ['id','first_name', 'last_name', 'email_no_message', 'phone_record', 'is_lp?']
    @records = SalesRep.none

    # -- Search stuff
    if params[:search_id]
      @search = UserSearch.where(id: params[:search_id]).first
    end
    # --

    # -- Filter / Scope Stuff
    @scope = 'active'
    scope_params = []
    if params[:scope].present?
      scope_params = SalesRep.scope_params_for([@scope])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, {"status"=>"active"})
      @records = @manager.scoped.paged_results(@page, @per_page, "first_name, last_name")
    else
      @manager = Managers::AdminTableManager.new(SalesRep, default_columns, scope_params)
      @records = []
    end

  end#scope_table

  # --
  def index
    @section = "merge"
    @user = User.new
  end

  def get_table_path(params)
    admin_tools_merge_reps_path(params)
  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_tools_merge_reps_path(search_id: search_id)
    @for = params[:for] if params[:for].present?
    @section = "merge"
    render action: :index
  end

  def table
    @merge_reps = true
    super
  end

private

end
