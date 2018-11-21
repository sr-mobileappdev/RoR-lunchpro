class AdminTableController < AdminController

  # -- Pagination for Dynamic Tables
  before_action :set_pagination, only: [:index, :table, :search, :office, :restaurant]
  before_action :scope_table, only: [:table]
  before_action :set_search, only: [:index, :search, :office, :restaurant]

  def set_pagination
    @sort = params[:sort] || nil
    @page = params[:page] || 1
    @per_page = params[:per_page] || Managers::AdminTableManager::DEFAULT_PER_PAGE
    if params[:title].present?
      @title = params[:title]
    end

    # -- Filter / Scope Stuff
    if params[:clear].present?
      session["#{params[:controller]}_scope"] = nil
    end
    @scope = (params[:scope].present?) ? params[:scope] : (session["#{params[:controller]}_scope"]) ? session["#{params[:controller]}_scope"] : nil
    session["#{params[:controller]}_scope"] = @scope
    # --

  end

  def table
    @custom_table_row_actions ||= []

    if @xhr
      render json: {  replace_state: get_table_path({for: params[:for], scope: (@scope) ? @scope : nil, sort: @sort, page: @page, per_page: @per_page, search_id: (@search && @search.id) ? @search.id : nil, title: (@title.present? ? @title :  nil)}),
                      column_count: @manager.columns.count + 1,
                      table_html: (render_to_string :partial => 'admin/shared/components/tables/dynamic_table', locals: {custom_row_actions: @custom_table_row_actions, merge_reps: @merge_reps}, :layout => false, :formats => [:html]),
                      pagination_html: (render_to_string :partial => 'admin/shared/components/tables/pagination', :layout => false, :formats => [:html]) }
    else
      head :ok
    end
  end

  def scope_tabel
    raise "scope_table must be implimented in the controller inheriting from AdminTableController"
  end

  # -- -- -- -- --


  # -- Search Stuff

  def enable_search
    @search_enabled = true
  end

  def set_search(klass = nil, for_action = nil)
    if @search_enabled && !klass
      raise "if search_enabled, set_search must be implimented in the controller inheriting from AdminTableController"
    end

    if params[:search_id].present?
      @search = UserSearch.where(id: params[:search_id]).first
    end
    @for = for_action
    @search ||= new_search(klass)
  end

  def search
    raise "search must be implimented in child of AdminTableController" unless @search_params

    if params[:search_id].present?
      @search = UserSearch.where(id: params[:search_id]).first
    end

    if @search && @search.id
      # Refresh an existing search
      set_conditions(@search, @search_params)

      @search.save
    else
      # New Search
      @search = new_search(@search.search_model)
      set_conditions(@search, @search_params)

      @search.save
    end

  end

  def new_search(klass)
    UserSearch.new(search_type: 'admin_query', search_model: klass, user_id: current_user.id, status: 1, conditions: {})
  end

  def set_conditions(search, search_params)
    conds = search.conditions

    conds["wheres"] ||= {}
    search_params.each do |key, val|
      conds["wheres"][key] = val
    end

    search.conditions = conds
  end

  # -- -- -- -- --

end
