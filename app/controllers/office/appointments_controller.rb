class Office::AppointmentsController < ApplicationOfficesController

  before_action :set_office, except: [:index]
  before_action :set_appointment, except: [:index, :show_open, :create, :exclude]
  before_action :check_order, only: [:select_food, :select_restaurant]

  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end

  def set_appointment
    @appointment = Appointment.where(id: params[:id]).first
    redirect_to "/404" if !@appointment || (!@appointment.belongs_to?(@office) && !params[:standby].present? && @appointment.internal?)
  end

  def set_office
    @office = current_user.user_office.office
  end

  def check_order    
    order = @appointment.current_order
    order = @appointment.recommended_order if !order || order.created_by_user.sales_rep
    #redirect_to current_office_calendars_path if order && !order.restaurant_editable?
  end

  def index
   @office = Office.includes(:appointment_slots).where(:id => current_user.user_office.office_id).first
  end

  def create

    #if office is schedudling appt for a new rep that doesnt exist
    if params[:create_rep].present? && [1, true, 'true'].include?(params[:create_rep])
      @slot = AppointmentSlot.find(params[:appointment][:appointment_slot_id]) 
      @appointment = Appointment.new(:status => 'active', :starts_at => @slot.starts_at, :ends_at => @slot.ends_at, 
      :office_id => @office.id, :created_by_user_id => @modifier_id, :origin => 'web')
      params[:appointment].delete :sales_rep_id

      appt_form = Forms::FrontendAppointment.new(current_user, allowed_params, @appointment, @modifier_id)

      rep_form = Forms::OmSalesRep.new(current_user, allowed_params, @office, appt_form)

      unless rep_form.valid?
        render :json => {success: false, general_error: "Unable to create new sales rep due to the following errors or notices:", errors: rep_form.errors}, status: 500
        return
      end

      # Model validations & save
      unless rep_form.save_and_invite
        render :json => {success: false, general_error: "Unable to create new sales rep at this time due to the following errors or notices:", errors: rep_form.errors}, status: 500
        return
      end
      if !rep_form.sales_rep.user
        Managers::NotificationManager.trigger_notifications([201], [rep_form.sales_rep, appt_form.appointment, @office]) 
      else
        Managers::NotificationManager.trigger_notifications([112], [rep_form.sales_rep, appt_form.appointment, @office]) 
      end
    #if a sample appointment
    elsif params[:samples_request].present?
      #return if no samples are present
      if !params[:appointment][:samples_requested].present?
        render :json => {success: false, general_error: "You must select at least one sample to be requested!"}, status: 500
        return
      end
      form = Forms::FrontendAppointment.new(current_user, allowed_params, nil, @modifier_id)

      unless form.valid?
        render :json => {success: false, general_error: "Unable to cancel appointment due to the following errors or notices:", errors: form.errors}, status: 500
        return
      end

       # Model validations & save
      unless form.save
        render :json => {success: false, general_error: "Unable to cancel appointment at this time due to a server error.", errors: form.errors}, status: 500
        return
      end
      #if office has requested an appointment to be scheduled
      if params[:require_appointment]
        Managers::NotificationManager.trigger_notifications([110], [form.appointment.sales_rep, form.appointment.office, form.appointment], 
          {include_sample_text: params[:send_as_text]}) 
      else
        Managers::NotificationManager.trigger_notifications([111], [form.appointment.sales_rep, form.appointment.office, form.appointment], 
          {include_sample_text: params[:send_as_text]})
      end
    else

      @slot = AppointmentSlot.find(params[:appointment][:appointment_slot_id]) 
      #if internal and no title provided
      if [1, true, 'true'].include?(params[:internal_appointment]) && !params[:appointment][:title].present?
        render :json => {success: false, general_error: "You must provide an appointment title."}, status: 500
        return
      end
      @appointment = Appointment.new(:status => 'active', :starts_at => @slot.starts_at, :ends_at => @slot.ends_at,
        :office_id => @office.id, :created_by_user_id => @modifier_id, :origin => 'web')
      form = Forms::FrontendAppointment.new(current_user, allowed_params, @appointment, @modifier_id)
      unless form.valid?
        render :json => {success: false, general_error: "Unable to create appointment due to the following errors or notices:", errors: form.errors}, status: 500
        return
      end

      unless form.save
        render :json => {success: false, general_error: "Unable to cancel appointment at this time due to a server error.", errors: form.errors}, status: 500
        return
      end
      #if not an internal appointment, trigger notification
      if ![1, true, 'true'].include?(params[:internal_appointment])
        Managers::NotificationManager.trigger_notifications([112], [form.appointment.sales_rep, form.appointment, @office]) 
      else
        Managers::NotificationManager.trigger_notifications([117], [form.appointment, @office]) 
      end
    end
    flash[:success] = "Appointment has been created!"
    redirect_to current_office_calendars_path
  end

  #used to 'exclude' a specific appointment slot on a specific day
  #creates a faux appointment marked as 'excluded' and will be unavailable for any reps
  def exclude
    @slot = AppointmentSlot.find(params[:appointment_slot_id])
    @appointment = Appointment.new(:status => 'active', :appointment_slot_id => @slot.id, :starts_at => @slot.starts_at, :excluded => true, 
      :ends_at => @slot.ends_at, :office_id => @office.id, :created_by_user_id => @modifier_id, :appointment_on => params[:appointment_on], :origin => 'web')

    unless @appointment.save
      render :json => {success: false, general_error: "Unable to exclude appointment at this time due to a server error.", errors: @appointment.errors.full_messages}, status: 500
      return
    end
    flash[:success] = "Appointment has been excluded!"
    redirect_to current_office_calendars_path
  end

  def cancel
    if @appointment.appointment_type == "internal"
      @appointment.assign_attributes(:cancelled_at => Time.now, :cancelled_by_id => @modifier_id, :status => 'inactive', :updated_by_id => @modifier_id)
      @order = @appointment.active_order
      if @appointment.save
        if @order
          @order.update(:status => 'inactive', :updated_by_id => @modifier_id, :cancelled_at => Time.now, :cancelled_by_id => @modifier_id) 
          @order.line_items.update_all(:status => 'deleted')
        end
      else
        render :json => {success: false, general_error: "Unable to cancel appointment at this time due to a server error.", errors: @appointment.errors.full_messages}, status: 500
        return
      end
      flash[:success] = "Appointment has been canceled!"
      redirect_to current_office_calendars_path
    elsif @appointment.excluded
       @appointment.assign_attributes(:cancelled_at => Time.now, :cancelled_by_id => @modifier_id, :status => 'inactive')
      unless @appointment.save
        render :json => {success: false, general_error: "Unable to cancel appointment at this time due to a server error.", errors: @appointment.errors.full_messages}, status: 500
        return
      end
      flash[:success] = "Appointment has been activated!"
      redirect_to current_office_calendars_path
    else
      form = Forms::FrontendAppointment.new(current_user, allowed_params, @appointment, @modifier_id)

      unless form.cancel("space_office")
        render :json => {success: false, general_error: "Unable to cancel appointment due to the following errors or notices:", errors: form.errors}, status: 500
        return
      end

       # Model validations & save
      unless form.save
        render :json => {success: false, general_error: "Unable to cancel appointment at this time due to a server error.", errors: form.errors}, status: 500
        return
      end

      flash[:success] = "Appointment has been canceled!"
      redirect_to current_office_calendars_path
    end
  end

  def update
    form = Forms::FrontendAppointment.new(current_user, allowed_params, @appointment, @modifier_id)

    unless form.valid?
      render :json => {success: false, general_error: "Unable to update appointment due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

     # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to update appointment at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    if params[:cuisine_recommendation]

      #TODO Confirm whether this is location for triggered notification on Cuisine Recommendation
      Managers::NotificationManager.trigger_notifications([106], [@appointment, @appointment.office, @appointment.appointment_slot, @appointment.sales_rep])

      redirect_to complete_office_appointment_path
    else
      redirect_to current_office_calendars_path
    end
  end

  def notify_standby
    @standby_reps = @office.listed_reps("standby")
    if @standby_reps.any?
      @standby_reps.each do |rep|
        Managers::NotificationManager.trigger_notifications([109], [rep, @appointment, @office])
      end
      standby_modal = "standby_notified"
    else
      standby_modal = "no_reps_on_standby"
    end
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/' + standby_modal, :layout => false, :formats => [:html])}
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    end
  end

  def show
    if @appointment
      @order_review = OrderReview.new
      if @appointment.sales_rep
        @offices_sales_rep = @appointment.sales_rep.offices_sales_reps.where(:office_id => @office.id, :status => 'active').first
      end
      if @appointment.food_ordered?
        @order = @appointment.current_order
        @order_review = @appointment.current_order.active_review('Office') || OrderReview.new(:order_id => @appointment.current_order.id)
      end
    end
    if @appointment && @appointment.cancelled_at.present? && @appointment.standby_filled?
      @standby_filled = true
    end
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/offices/appointments/om_' + @appointment.office_appointment_modal, locals: {office_view: params[:office_view]}, :layout => false, :formats => [:html])}
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    end
  end

  def confirm
    @appointment.confirm_for_office!
    @appointment.confirm_for_rep!
    redirect_to current_office_calendars_path
  end

  def complete
    redirect_to current_office_calendars_path if !@appointment.cuisine_recommended? && !@appointment.show_order_recommendation?
  end

  def select_restaurant
    if !@appointment.active? || @appointment.is_sample? || !@appointment.upcoming?
      redirect_to current_office_calendars_path and return 
    elsif @appointment.active_order
      redirect_to select_food_office_appointment_path(@appointment) and return
    end
    #if appointment is internal, cannot sort by relevance, set average sort to rating high to low
    if @appointment.internal?
      redirect_to office_appointment_path(@appointment) and return if !@appointment.active?
      @restaurants = @office.filtered_available_restaurants(@appointment, nil, session[:impersonator_id].present?)
      @sort_values = Restaurant.sort_by_values
      @sort_values.delete_if {|sort| sort[:value] == "relevance"}
      @restaurants = Managers::SortManager.new(Restaurant, @restaurants, "average_overall_rating^desc", nil).results
    else
      @sort_values = Restaurant.sort_by_values
      @restaurants = @office.filtered_available_restaurants(@appointment, @appointment.sales_rep.user, session[:impersonator_id].present?)

      #default sort  relevance
      @restaurants = Managers::SortManager.new(Restaurant, @restaurants, "relevance", @appointment.sales_rep).results
    end
  end

  def select_food
    # If the user changes the restaurant, clear out the cart
    ###Divided the logic for an internal appointment vs a recommended order 
    session[:cart] ||= []
    order = nil
    cached_order = nil
    order = @appointment.current_order
    order = @appointment.recommended_order if !order || order.created_by_user.sales_rep
    redirect_to current_office_calendars_path and return if (order && 
      (!order.restaurant_editable? && order.active?) && !session[:impersonator_id].present? ) || @appointment.is_sample?

    if order
      restaurant = order.appointment.restaurant || order.restaurant      
      if restaurant && params[:restaurant_id].present? && restaurant.id != params[:restaurant_id].to_i
        order.line_items.update(:status => 'deleted')
        order.update(:updated_by_id => @modifier_id)
        order.update_total 
      end
    end    
    if order && order.active?
      if !session[:cart].select{|cached_order| cached_order['order_id'] == order.id}.any?
        cached_order = {:order_id => order.id, :line_items => order.line_items.active.pluck(:id)}
        session[:cart] << {:order_id => order.id, :line_items => order.line_items.active.pluck(:id)}
      else
        cached_order = session[:cart].select{|cached_order| cached_order['order_id'] == order.id}.first
      end
    end

    if @appointment.internal?      
      if params[:restaurant_id].present?
        @appointment.update(restaurant_id: params[:restaurant_id])        
        order.update(restaurant_id: params[:restaurant_id], :updated_by_id => @modifier_id) if order
      end
      @restaurant = @appointment.restaurant
      order = order || Order.create(appointment_id: @appointment.id, restaurant_id: @restaurant.id,
      :created_by_user_id => @modifier_id, :status => 'draft', :updated_by_id => @modifier_id)

    else     
      if params[:restaurant_id].present?
        @restaurant = Restaurant.find(params[:restaurant_id])
        order.update(restaurant_id: params[:restaurant_id], :updated_by_id => @modifier_id) if order
      end

      order = order || Order.create(:updated_by_id => @modifier_id, appointment_id: @appointment.id, restaurant_id: @restaurant.id,
      :created_by_user_id => @modifier_id, :recommended_by_id => @modifier_id, :status => 'draft', :sales_rep_id => @appointment.sales_rep_id)

      @restaurant = order.restaurant if order
      @total_budget = order.appointment.total_budget_for_appointment
      @total_budget = nil if @total_budget == 0
    end

    if cached_order && cached_order['line_items']
      @line_items = LineItem.find(cached_order['line_items']) 
      @edit_in_progress = true if order.line_items.active.pluck(:id) != @line_items.pluck(:id)
    else
      @line_items = order.line_items.active
    end
    @menus = @restaurant.filtered_menus_by_time(@appointment.starts_at)

    unless order.id
      puts order.errors.full_messages
      raise "Order failed to save"
    end
    @order = order
    @order.update(:restaurant_id => @restaurant.id)
  end

  def filter_restaurants

    @restaurants = Appointment::FilteredRestaurants.new(@office, params.permit(:cuisines => [], :price_range => []), @appointment, nil, session[:impersonator_id].present?).filtered

    render json: { template: (render_to_string :partial => 'rep/appointments/components/filtered_restaurants', locals: {restaurants: @restaurants}, :layout => false, :formats => [:html]) }

  end

  def sort_restaurants
    sort_by = "relevance"
    sort_by = params[:sort_by] if params[:sort_by].present?
    restaurants = Restaurant.where(id: params[:restaurant_ids]) if params[:restaurant_ids].present?
    return if !restaurants.present?
    @sort_manager = Managers::SortManager.new(Restaurant, restaurants, sort_by, @appointment.sales_rep)

    restaurants = @sort_manager.results

    render json: {templates: {
                    targ__restaurant_list: (render_to_string :partial => 'rep/appointments/components/filtered_restaurants_list', locals: {appointment: @appointment, restaurants: restaurants}, :layout => false, :formats => [:html])
                    }
                  }
  end

  def cancel_recommendation
    if params[:type] == 'cuisine'
      @appointment.update_attributes!(:recommended_cuisines => nil)
      flash[:success] = "Cuisine recommendation has been canceled!"
      redirect_to current_office_calendars_path
    elsif params[:type] == 'modal_cuisine'
      @appointment.update_attributes!(:recommended_cuisines => nil)
      flash[:success] = "Cuisine recommendation has been canceled!"
      redirect_to current_office_calendars_path
    elsif params[:type] == 'exact'
      @appointment.update_attributes!(:recommended_cuisines => nil)
      @appointment.recommended_order.update(:status => 'deleted')
      flash[:success] = "Exact order recommendation has been canceled!"
      redirect_to current_office_calendars_path
    end

  end

  def recommendation
    if @appointment.food_ordered? || @appointment.is_sample? || !@appointment.upcoming?
      redirect_to current_office_calendars_path
    end
    @cuisines = Cuisine.active.select(:id, :name).to_json
  end

  def edit_recommendation
    if @appointment.cuisine_recommended?
       @cuisines = Cuisine.active.select(:id, :name).to_json
       @recommended_cuisines = @appointment.recommended_cuisines.map(&:inspect).join ','
    elsif @appointment.show_order_recommendation?
      redirect_to select_food_office_appointment_path(@appointment, restaurant_id: @appointment.restaurant_id)
    else
      redirect_to current_office_calendars_path
    end
  end
  # The current overall calendar for a single rep, across all offices
  def current

  end

  private
  def allowed_params
    groupings = [:appointment, :user, :office, :sales_rep]

    super(groupings, params)
  end

end
