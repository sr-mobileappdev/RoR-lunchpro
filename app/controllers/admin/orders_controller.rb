class Admin::OrdersController < AdminTableController

  before_action :set_record, only: [:send_receipt, :show, :edit, :update, :select_item, 
    :add_item, :remove_item, :confirm, :decline, :manual_complete]
  before_action :enable_search, only: [:index]
  def set_record
    @record = Order.find(params[:id])
  end

  def set_search
    @available_scopes = []
    klass = "Order"
    @search_path = search_admin_orders_path
    super(klass)
  end

  def search
    @search_params = params[:conditions].permit!
    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_orders_path(search_id: search_id)

    render :index
  end

  # -- Scope Table
  def scope_table
    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

		default_columns = ['order_number','delivery_date','delivery_time','restaurant_name']#, 'restaurant_confirmed']
    @records = Order.none

    # -- Filter / Scope Stuff
    @scope = nil
    scope_params = ['not_recommended']
    if params[:scope].present?
      @scope = params[:scope]
      scope_params = Order.scope_params_for([@scope, 'not_recommended'])
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page)
      @records = @records.sort_by{|r| [r.order_date, r.order_delivery_time]}
    else
      #@manager = Managers::AdminTableManager.new(Order, default_columns, scope_params)
      #@records = @manager.scoped.paged2(@page, @per_page)
      case @scope
        when "unconfirmed" #active order unconfirmed
          @manager = Managers::AdminTableManager.new(Order, default_columns, scope_params, nil, :appointment)
          @records = @manager.scoped.paged2(@page, @per_page, 'appointments.appointment_on desc, appointments.starts_at desc')
          @records = @records.select{|r| !r.confirmed?} #ensures it's NOT confirmed
          @records = @records.select{|r| !r.inactive?}  #ensures it's active
          #@records = @manager.scoped.paged_results(@page, @per_page)
          #fix pagination

        when "confirmed" #active order confirmed
          @manager = Managers::AdminTableManager.new(Order, default_columns, scope_params, nil, :appointment)
          @records = @manager.scoped.paged2(@page, @per_page, 'appointments.appointment_on desc, appointments.starts_at desc')
          @records = @records.select{|r| r.confirmed?}
          @records = @records.select{|r| !r.inactive?}
          #fix pagination
        when "past"
          @manager = Managers::AdminTableManager.new(Order, default_columns, scope_params, nil, :appointment)
          @records = @manager.scoped.paged2(@page, @per_page, 'appointments.appointment_on desc, appointments.starts_at desc')
        when "inactive"
          @manager = Managers::AdminTableManager.new(Order, default_columns, scope_params, nil, :appointment)
          @records = @manager.scoped.paged2(@page, @per_page, 'appointments.appointment_on desc, appointments.starts_at desc')

        when nil #no tab selected
          @manager = Managers::AdminTableManager.new(Order, default_columns, scope_params, nil, :appointment)
          @records = @manager.scoped.paged2(@page, @per_page, 'appointments.appointment_on desc, appointments.starts_at desc')          
      end

      #@records = @manager.scoped.paged(@page, @per_page)
      #byebug
      #if @scope == 'inactive'
          #@records = @records.select{|r| r.confirmed?}
      #elsif @scope == 'unconfirmed'
          #@records = @records.select{|r| !r.confirmed?}
      #end
      #@records = @records.sort_by{|r| [r.order_date, r.order_delivery_time]}.reverse!
    end
  end

  def get_table_path(params)
    admin_orders_path(params)
  end
  # --

  def index
    @available_scopes = [{scope: 'unconfirmed', title: 'Unconfirmed'}, {scope: 'confirmed', title: 'Confirmed'}, {scope: 'past', title: 'Order History'}, {scope: 'inactive', title: 'Cancelled'}]
    @scope = params[:scope]
    @title = params[:title]
  end

  def new
    # Related stories -- Appointment creation


    @record = Order.new(created_by_id: current_user.id, timezone: Constants::DEFAULT_TIMEZONE)
    @record.user = User.new()
  end

  def show
    @back_url = find_back_url_from_origin

  end

  def edit

  end

  def select_item
    @item = MenuItem.find(params[:item_id])

    if params[:line_item_id].present?
      @base_line_item = LineItem.find(params[:line_item_id])
    else
      @base_line_item = LineItem.new(orderable: @item, quantity: 1, created_by_id: current_user.id)
    end

    if @xhr
      render json: { html: (render_to_string :partial => 'select_item', locals: {item: @base_line_item.orderable}, :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
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
        csv_data = man.generate_upcoming_orders(current_user, true)
        filename = "admin_upcoming_orders"
      when 'past'
        csv_data = man.generate_past_orders(current_user, true)
        filename = "admin_past_orders"
    end


    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data,
      :type => 'text/csv',
      :disposition => "attachment; filename=#{filename}_#{Time.now.to_date}.csv"
  end

  def remove_item
    @line_item = LineItem.find(params[:line_item_id])
    @line_item.destroy

    @record.update_total

    redirect_to edit_admin_office_order_path(@record.office, @record, step: 2), alert: 'Item has been removed from order'
  end

  def create

    form = Forms::AdminOrder.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new appointment due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new order at this time due to a server error.", errors: []}, status: 500
      return
    end

    flash[:notice] = "Order has been created."
    render :json => {success: true, redirect: admin_sales_rep_path(sales_rep) }
    return

  end

  def update

    line_item = Forms::AdminOrderLineItem.new(current_user, @record, allowed_params)

    notice = ""
    if line_item.valid? && line_item.save
      notice = "Item added to your order"
    else
      notice = "Unable to add item due to the following errors: #{line_item.errors.join(',')}"
    end

    redirect_to edit_admin_office_order_path(@record.office, @record, step: 2), notice: notice

  end

  def confirm
    unless @record.appointment.confirm_for_restaurant!
      render json: {success: false, general_error: "Unable to confirm this order at this time due to a server error", errors: []}, status: 500
    end

    flash[:notice] = "Order Number '#{@record.order_number}' has been confirmed"
    redirect_to admin_orders_path(scope: params[:scope])
  end

  def decline
    @record.restaurant_cancelled = true      #virtual attr to bypass order notif triggers
    @record.update_attributes(status: 'inactive', cancelled_at: Time.now, cancelled_by_id: current_user.id)
    @record.appointment.update_attributes(restaurant_confirmed_at: nil)

    Managers::NotificationManager.trigger_notifications([301],
      [@restaurant, @record, @record.appointment, @record.appointment.office], {poc: current_user.poc_info})

    flash[:alert] = "Order has been declined"
    redirect_to admin_orders_path(scope: params[:scope])
  end

  def manual_complete
    if @record.status != 'completed'
      @record.update_attributes(status: 'completed', updated_at: Time.now, updated_by_id: current_user.id)
      flash[:alert] = "Order has been manually completed."
      redirect_to admin_orders_path(scope: params[:scope])
    else
      flash[:alert] = "Order has already been completed."
      redirect_to admin_orders_path(scope: params[:scope])
    end
  end


  def send_receipt
    return if !@record.appointment || !@record.appointment.sales_rep
    if @record.appointment.sales_rep
      Managers::NotificationManager.trigger_notifications([402], [@record, @record.appointment,
       @record.appointment.sales_rep, @record.appointment.sales_rep.user])
    elsif @record.appointment.internal?
      Managers::NotificationManager.trigger_notifications([402], [@record, @record.appointment, @record.customer, @record.appointment.office])
    end
    flash[:notice] = "Order Receipt has been sent to the orderer."
    redirect_to request.referrer
  end

private

  def allowed_params
    groupings = [:appointment, :user, :office, :sales_rep, :line_item]

    super(groupings, params)
  end

  def find_back_url_from_origin
    if params[:restaurant_id].present?
      admin_restaurant_orders_path(params[:restaurant_id])
    elsif params[:office_id].present?
      admin_office_orders_path(params[:office_id])
    elsif params[:sales_rep_id].present?
      admin_sales_rep_orders_path(params[:sales_rep_id])
    elsif params[:appointment_id].present?
      admin_appointment_path(params[:appointment_id])
    else
      "javascript:history.back()"
    end
  end

end
