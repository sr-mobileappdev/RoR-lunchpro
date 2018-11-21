class Admin::RewardsController < AdminTableController
  # NOTE: Routes file has path for this controller set to /reps/, for visual clarity

  before_action :set_record, only: [:show, :edit, :edit_points, :update]

  # -- Enable Search
  before_action :enable_search, only: [:index]

  def set_search
    @available_scopes = [{scope: 'active', title: 'Active Reps'}]
    klass = "SalesRep"
    @search_path = search_admin_rewards_path
    super(klass)
  end
  # --

  def set_record
    @record = SalesRep.find(params[:id])
  end

  # -- Scope Table
  def scope_table
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    default_columns = ['id','display_name', 'reward_points', 'display_reward_date']
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
      @records = @manager.scoped.paged_results(@page, @per_page)
      @section = "rewards"
    else
      @manager = Managers::AdminTableManager.new(SalesRep, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page)
      @section = "rewards"
    end

  end#scope_table

  def get_table_path(params)
    admin_rewards_path(params)
  end
  # --

  def index

    @available_scopes = [{scope: 'active', title: 'Active Reps'}]

  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_rewards_path(search_id: search_id)

    render :index
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
    end


    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data,
      :type => 'text/csv',
      :disposition => "attachment; filename=#{filename}_#{Time.now.to_date}.csv"
  end

  def edit_points
    @record = SalesRep.find(params[:id])
    if @xhr
      if params[:is_modal] == 'true'
        render :json => { html: (render_to_string partial: 'admin/rewards/edit_points', layout: false, formats: [:html]) }
        return
      else
        raise "Opening modal view without passing is_modal=true"
      end
    end
  end

  def update
    @record.assign_attributes(reward_points: params[:sales_rep][:reward_points], last_reward_date: params[:sales_rep][:last_reward_date])

    unless @record.save
      render json: {success: false, general_error: "The rewards for this Sales Rep could not be updated at this time", errors: @record.errors}, status: 500
      return
    end

    flash[:success] = "The rewards points for this Sales Rep have been updated!"
    redirect_to request.referrer
  end

private

  def allowed_params
    groupings = [:sales_rep, :user]

    super(groupings, params)
  end

end
