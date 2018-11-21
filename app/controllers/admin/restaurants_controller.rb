class Admin::RestaurantsController < AdminTableController
  before_action :set_record, only: [:show, :edit, :update, :activate, :deactivate, :delete, :upload_asset, :complete_upload_asset, :preferences, :registration, :upload_partial]
  before_action :set_new_availabilities, only: [:edit, :preferences, :registration]
  before_action :set_menu, only: [:registration]
  before_action :set_menu_item, only: [:registration]
  before_action :set_new_user, only: [:registration]
  before_action :set_bank_account, only: [:registration]
  after_action :set_new_availabilities, only: [:registration]
  after_action :set_record, only: [:create, :update]

  # -- Enable Search
  before_action :enable_search, only: [:index]

  def set_search
    @available_scopes = [{scope: 'active', title: 'Active Restaurants'}, {scope: 'inactive', title: 'Deactivated Restaurants'}]
    klass = "Restaurant"
    @search_path = search_admin_restaurants_path
    super(klass)
  end
  # --

  def set_record

    if !@restaurant && !params[:id]
      @restaurant = Restaurant.new(created_by_id: current_user.id, timezone: Constants::DEFAULT_TIMEZONE)
      @restaurant.restaurant_pocs.build
    elsif !@restaurant
      @restaurant = Restaurant.find(params[:id])
    end
  end

  def set_menu
    if params[:menu_id]
      @menu = Menu.find(params[:menu_id])
    else
      @menu = Menu.new(restaurant_id: @restaurant.id, created_by_user_id: current_user.id)
    end
  end

  def set_menu_item
    if params[:menu_item_id]
      @menu_item = MenuItem.find(params[:menu_item_id])
    else
      @menu_item = MenuItem.new(restaurant_id: @restaurant.id)
    end
  end

  def set_new_user
    @restaurant_user = UserRestaurant.new(restaurant_id: @restaurant.id, created_by_id: current_user.id)
    @restaurant_user.user = User.new()
  end

  def set_bank_account
    @bank_account = BankAccount.new(restaurant_id: @restaurant.id, created_by_id: current_user.id)
  end

  def set_new_availabilities
    RestaurantAvailability.dows.each do |day, number|
      avail = @restaurant.restaurant_availabilities.find_by(day_of_week: number)
      if avail.present?
        #if one already exists for this weekday, skip
      else
        # else create a new one
        @restaurant.restaurant_availabilities.build(day_of_week: number, status: 'inactive')
      end
    end
  end

  def preferences

  end

  # -- Scope Table
  def scope_table
    default_columns = ['id','name','display_location_single','headquarters_id']

    # AdminTableController manages definiation of @page, @per_page and @sort as well as establishing the table controller method, handling pagination, etc.
    # This method is required for all controllers that inherit from AdminTableController

    @records = Restaurant.none

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
      options = {}

      # Handling the situation where we want to only show restaurants available for a specific office, based on driving radius
      if @scope == "for_office" && params[:for_office_id]
        man = Managers::AdminTableManager.new(Restaurant, default_columns, scope_params)
        available_restaurant_ids = man.for_office(Office.find(params[:for_office_id])).pluck(:id)
        options[:limit_to_ids] = available_restaurant_ids
        # A food order is being placed for an appointment
        if params[:appointment_id].present?
          appointment = Appointment.find(params[:appointment_id])
          @custom_table_row_actions = [{'select_restaurant_for_order' => {office_id: params[:for_office_id], appointment: appointment}}]
        end

      end

      scope_params = Restaurant.scope_params_for([@scope], options)
    end
    # --

    if @search && @search.id
      @manager = Managers::AdminSearchManager.new(@search, default_columns, scope_params)
      @records = @manager.scoped.paged_results(@page, @per_page, "name")
    else
      @manager = Managers::AdminTableManager.new(Restaurant, default_columns, scope_params)
      @records = @manager.scoped.paged(@page, @per_page, nil, "name")
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
        csv_data = man.generate_active_restaurants(current_user)
        filename = "admin_active_restaurants"
      when 'inactive'
        csv_data = man.generate_inactive_restaurants(current_user)
        filename = "admin_inactive_restaurants"
      when 'payout'
        start_date = params[:start_date] || ((Date.today) + (Date.today.wday - 6) * -1) - 7
        end_date = params[:end_date] || Date.today.to_date

        csv_data = man.generate_restaurant_weekly_payout(current_user, start_date, end_date)
        filename = "admin_weekly_payout"
    end


    unless !man.errors.any?
      flash[:alert] = "There was an error processing your request."
      redirect_to request.referrer and return
    end
    send_data csv_data,
      :type => 'text/csv',
      :disposition => "attachment; filename=#{filename}_#{start_date}-to-#{end_date}.csv"
  end

  def get_table_path(params)
    admin_restaurants_path(params)
  end
  # --

  def search
    @search_params = params[:conditions].permit!

    super()

    search_id = (@search && @search.id) ? @search.id : params[:search_id]
    @search_path = search_admin_restaurants_path(search_id: search_id)

    render :index
  end

  def index

    @available_scopes = [{scope: 'active', title: 'Active Restaurants'}, {scope: 'inactive', title: 'Deactivated Restaurants'}]

  end

  def new
    @restaurant = Restaurant.new(created_by_id: current_user.id, timezone: Constants::DEFAULT_TIMEZONE)
    @restaurant.restaurant_pocs.build
    # redirect to the registration index path admin_restaurants_registration_index_path?
  end

  def registration

  end

  def create

    form = Forms::AdminRestaurant.new(current_user, allowed_params)
    unless form.valid?
      render :json => {success: false, general_error: "Unable to create new restaurant due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

    # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to create new restaurant at this time due to a server error.", errors: []}, status: 500
      return
    end

    @restaurant = form.restaurant
    render json: { success: true, redirect: registration_admin_restaurant_path(id: @restaurant.id)}
    return

  end

  def update
    form = Forms::AdminRestaurant.new(current_user, allowed_params, @restaurant)

    unless form.save
      if form.errors
        render :json => {success: false, general_error: "Unable to update restaurant due to the following errors or notices:", errors: form.errors}, status: 500
        return
      else
        render :json => {success: false, general_error: "Unable to update restaurant due to a server error", errors: []}, status: 500
        return
      end
    end

    @restaurant.update(allowed_upload_params)

    flash[:notice] = "Restaurant has been updated."
    if params[:wizard] == 'true'
      render json: { success: true, reload: true }
      return
    else
      redirect_to admin_restaurant_path(@restaurant), notice: 'Restaurant has been updated'
      return
    end

  end

  def activate
    unless @restaurant.can_activate?
      if params[:wizard] == 'true'
        errors = []
        @restaurant.activation_notices.each do |notice|
          errors << notice[:message]
        end
        render :json => {success: false, general_error: "Restaurant cannot yet be activated due to the noted missing activation requirements:", errors: errors}, status: 500
        return
      else
        flash[:alert] = "Restaurant cannot yet be activated due to the noted missing activation requirements."
        render :json => {success: false}
        return
      end
    end

    @restaurant.update_attributes(activated_at: Time.now, deactivated_at: nil, status: "active")

    # Restaurant activation notification
    Managers::NotificationManager.trigger_notifications([405], [@restaurant])

    flash[:notice] = "Restaurant has been activated within the LunchPro system. They can now receive orders."
    render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
  end

  def deactivate
    if @restaurant.is_headquarters? && @restaurant.restaurants.any?
      flash[:alert] = "You cannot deactivate a Headquarters Restaurant with active child restaurants!"
      render :json => {success: false, redirect: admin_restaurant_path(@restaurant) }
      return
    end
		if @restaurant.orders.where(:status => 'active').count == 0
			prior_status = @restaurant.status
			@restaurant.update_attributes(deactivated_at: Time.now, status: 'inactive', :deactivated_by_id => current_user.id)
			flash[:alert] = "Restaurant has been deactivated within the LunchPro system. They will no longer be able to receive order, however existing orders that are not cancelled may still need to be fulfilled."
			render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
		else
			flash[:alert] = "You cannot deactivate a restaurant when there is outstanding orders!"
			render :json => {success: false, redirect: admin_restaurant_path(@restaurant) }
      return
    end
  end

  def delete
    if @restaurant.is_headquarters? && @restaurant.restaurants.any?
      flash[:alert] = "You cannot deactivate a Headquarters Restaurant with active child restaurants!"
      render :json => {success: false, redirect: admin_restaurant_path(@restaurant) }
      return
    end
    if @restaurant.orders.where(:status => 'active').count == 0
      prior_status = @restaurant.status
      @restaurant.update_attributes(deactivated_at: Time.now, status: 'inactive',  :deactivated_by_id => current_user.id)
      flash[:alert] = "Restaurant has been deactivated within the LunchPro system. They will no longer be able to receive order, however existing orders that are not cancelled may still need to be fulfilled."
      render :json => {success: true, redirect: admin_restaurant_path(@restaurant) }
    else
      flash[:alert] = "You cannot deactivate a restaurant when there is outstanding orders!"
      render :json => {success: false, redirect: admin_restaurant_path(@restaurant) }
      return
    end
  end

  def upload_asset
    @record = @restaurant
    if @xhr
      if params[:wizard] == 'true'
        render json: { html: (render_to_string :partial => 'admin/shared/components/uploader_popup', locals: {upload_path: complete_upload_asset_admin_restaurant_path(@record, wizard: true), upload_param: :brand_image}, :layout => false, :formats => [:html]) }
      else
        render json: { html: (render_to_string :partial => 'admin/shared/components/uploader_popup', locals: {upload_path: complete_upload_asset_admin_restaurant_path(@record), upload_param: :brand_image}, :layout => false, :formats => [:html]) }
      end
      return
    else
      head :ok
    end
  end

  def upload_partial
    render json: { templates: {
                    targ__restaurant_image_upload: (render_to_string partial: 'admin/restaurants/components/image_upload', layout: false, formats: [:html])
      }
    }
  end

  def complete_upload_asset
    if params[:restaurant].present?
      image_from_client = parse_image_data(params[:image_data])
      @restaurant.assign_attributes(:brand_image => image_from_client)
      @restaurant.save(validate: false)

      clean_tempfile

      if params[:wizard] == 'true'
        render json: { success: true, reload_logo: true}
        return
      else
        flash[:notice] = "#{@restaurant.name}'s logo image has been updated"
        redirect_to admin_restaurant_path(@restaurant)
      end
      return
    end
  end


  private

  def parse_image_data(base64_image)
    filename = "restaurant-logo"
    in_content_type, encoding, string = base64_image.split(/[:;,]/)[1..3]

    @tempfile = Tempfile.new(filename)
    temp_file_path = @tempfile.path
    @tempfile.binmode
    @tempfile.write Base64.decode64(string)
    @tempfile.rewind

    content_type = params[:image_file_type]
    # we will also add the extension ourselves based on the above
    # if it's not gif/jpeg/png, it will fail the validation in the upload model
    extension = content_type.match(/gif|jpeg|png/).to_s
    filename += ".#{extension}" if extension
    ActionDispatch::Http::UploadedFile.new({
      tempfile: @tempfile,
      content_type: content_type,
      filename: filename
    })
  end

  def clean_tempfile
    if @tempfile
      @tempfile.close
      @tempfile.unlink
    end
  end

  def allowed_upload_params
    params.require(:restaurant).permit(:brand_image)
  end

  def allowed_params
    groupings = [:restaurant, :delivery_distance]
    individual = [:trig__radius, :restaurant_cuisines]

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
    individual.each do |param|
      allowed[param] = params[param]
    end
    authed_params = ActionController::Parameters.new(allowed)
    authed_params
  end


end
