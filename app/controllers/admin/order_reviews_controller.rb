class Admin::OrderReviewsController < AdminTableController

  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :delete]

  # -- Enable Search
  before_action :enable_search, only: [:index]

  def set_search
    klass = "OrderReview"
    @search_path = search_admin_order_reviews_path
    super(klass)
  end
  # --

  def set_record
    @record = OrderReview.find(params[:id])
  end

  # -- Scope Table
  def scope_table
    default_columns = ['id','name']
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = OrderReview.none

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
      scope_params = OrderReview.scope_params_for([@scope])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page)
    else
      @manager = Managers::AdminTableManager.new(OrderReview, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page)
    end

  end

  def report
    ## TO DO handle scope param if requested ##

    man = Managers::CsvManager.new
    csv_data = man.generate_order_reviews(current_user)
    filename = "admin_order_reviews"

    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data, 
      :type => 'text/csv', 
      :disposition => "attachment; filename=#{filename}_#{Time.now.to_date}.csv"
  end

  def get_table_path(params)
    admin_order_reviews_path(params)
  end
  # --

  def index

    @available_scopes = [{scope: 'recent', title: 'Recent'}, {scope: 'active', title: 'All Reviews'}]

  end

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_order_reviews_path(search_id: search_id)

    render :index
  end

  def new
    @record = OrderReview.new(created_by_id: current_user.id)
    @record.user = User.new()
  end

  def create

    form = Forms::AdminOrderReview.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new order review due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new order review at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Sales rep has been created & invited to LunchPro."
    render :json => {success: true, redirect: admin_order_review_path(form.sales_rep) }
    return

  end

  def update

    form = Forms::AdminOrderReview.new(current_user, allowed_params, @record)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to update order review due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update order review at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Review has been updated."
    render :json => {success: true, redirect: admin_order_review_path(form.sales_rep) }
    return

  end

  def activate
    @record.update_attributes(activated_at: Time.now, deactivated_at: nil, status: "active")

    flash[:notice] = "Review has been re-activated within the LunchPro system."
    render :json => {success: true, redirect: admin_order_review_path(@record) }
  end

  def deactivate
    prior_status = @record.status
    @record.update_attributes(deactivated_at: Time.now, status: 'inactive')

    flash[:alert] = "Review has been deactivated within the LunchPro system."
    render :json => {success: true, redirect: admin_order_review_path(@record) }
  end

  def delete
    prior_status = @record.status
    @record.deleted!

    flash[:alert] = "Review has been removed from the system. This will only appear in historical reports, where applicable."
    render :json => {success: true, redirect: admin_order_reviews_path() }
  end

private

  def allowed_params
    groupings = [:order_review]

    super(groupings, params)
  end

end
