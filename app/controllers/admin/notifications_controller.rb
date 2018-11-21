class Admin::NotificationsController < AdminTableController

  # -- Enable Search
  before_action :enable_search, only: [:index]

  def set_search
    @available_scopes = [{scope: 'active', title: 'All Notifications'}, {scope: 'notified', title: 'Notified'}]
    klass = "Notification"
    @search_path = search_admin_notifications_path
    super(klass)
  end
  # --

  # -- Scope Table
  def scope_table
    default_columns = ['id','user_email','title','created_at','notified_at', 'web_summary']

    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = Notification.none

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
      scope_params = Notification.scope_params_for([@scope])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page)
    else
      @manager = Managers::AdminTableManager.new(Notification, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page)
    end

  end#scope_table

  def get_table_path(params)
    admin_notifications_path(params)
  end
  # --

  def index

  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_notifications_path(search_id: search_id)

    render :index
  end

  def show
    @notification = Notification.find(params[:id])

    if @notification.appointment
      redirect_to admin_appointment_path(@notification.appointment)
    elsif @notification.sales_rep
      redirect_to admin_sales_rep_path(@notification.sales_rep)
    elsif @notification.office
      redirect_to admin_office_path(@notification.office)
    end
  end

  def remove
    @notification = Notification.find(params[:id])
    @notification.read_at ||= Time.now
    @notification.removed_at = Time.now

    @notification.save

    #Managers::ActioncableManager.new("notification_refresh", "admin_notifications_#{@notification.user_id}").broadcast({badge_count: @notification.user.notifications.visible.count})
    # Silent response
    head :ok
  end

end
