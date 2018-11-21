class Rep::AppointmentsController < ApplicationRepsController
  before_action :set_appointment, except: [:index, :new, :policies, :prompt_schedule, :create, :book_standby, :display_duplicate, :schedule]
  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end

  def set_appointment

    @record = Appointment.where(id: params[:id]).first
    redirect_to "/404" if !@record || (!@record.belongs_to?(current_user.sales_rep) && !params[:standby].present?)
    @appointment = @record
  end

  def new
    get_my_offices
    @active_offices = []
  end

  def policies
    @office = Office.where(id: params[:office_id]).first
    redirect_to current_rep_calendars_path and return if !@office || !@office.active?
    if params[:appointment_id].present?
      @appointment = Appointment.find(params[:appointment_id])
    end

    @back = ""
    if params[:back].present?
      @back = params[:back]
    end
    
    @start_date = params[:start]
  end

  # List of reps offices
  def index

  end

  def update
    form = Forms::FrontendAppointment.new(current_user, allowed_params, @record, @modifier_id)

    cancel_orders = false
    
    if params[:appointment][:will_supply_food].present?
      cancel_orders = true
    end

    unless form.valid? && form.save(cancel_orders)
      render :json => {success: false, general_error: "Unable to update appointment due to the following errors or notices:", errors: form.errors}, status: 500
    return
    end
    flash[:success] = "Appointment has been updated!"
    if params[:redirect_to].present?
      redirect_to_tab(params[:redirect_to])
    else
      redirect_back(fallback_location: root_path)
    end
  end

  #used for creating appoints for non lp
  def schedule
    @office = Office.find(params[:office]) if params[:office].present?
    if !@office
      redirect_to new_rep_order_path and return
    end
    @record = Appointment.new(:office_id => @office.id, :origin => 'web')
  end

  def finish
    if @xhr && modal?
      @modal = true
    end
  end

  #used for creating appointments from /orders/set_delivery
  def create
    if params[:set_delivery].present?
      form = Forms::FrontendAppointment.new(current_user, allowed_params, nil, @modifier_id)

      unless params[:force_duplicate] && params[:force_duplicate] == 'true'
        appt = Appointment.new(status: 'active', created_by_user_id: @modifier_id, sales_rep_id: current_user.sales_rep.id)
        appt.assign_attributes(allowed_params[:appointment])
        duplicate_appts = @current_user.sales_rep.check_for_duplicate_appointments([appt], true)
        if duplicate_appts.any?
          render :json => {duplicate: true} and return
        end
      end

      unless form.valid?(check_if_past = true) && form.save
        render :json => {success: false, general_error: "Unable to create appointment due to the following errors or notices:", errors: form.errors}, status: 500
      return
      end
      appointment = form.appointment
      Managers::NotificationManager.trigger_notifications([202], [appointment, appointment.office, appointment.sales_rep])
      redirect_to finish_rep_appointment_path(form.appointment)
    end
  end
  # Individual office detail view
  def show
    if @xhr
      if modal?
        modal = @record.rep_appointment_modal
        if !modal
          render json: { success: false}
          return
        end
        if modal == "past_appointment"
          @office_order_review = @record.active_order.active_review('Office') if @record.active_order
        end
        if @record && @record.cancelled_at.present? && @record.standby_filled?
          @standby_filled = true
        end
        if params[:order_id].present?
          @order = Order.find(params[:order_id])
        end
        if params[:notification_id].present?
          @notif = Notification.find(params[:notification_id])
        end
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/appointments/rep_' + modal, locals: {office_view: params[:office_view]}, :layout => false, :formats => [:html])}
        return
      else
        raise "Opening model view without passing is_modal=true"
      end
    else
      @appointment_partial = @record.rep_appointment_partial
    end
  end

  def show_sample
    if @xhr
      if modal?
        drugs = Drug.find(@record.samples_requested)
        if params[:require_appointment]
          render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/appointments/rep_sample_appointment', 
            locals: {require_appointment: true, drugs: drugs}, :layout => false, :formats => [:html])}
          return
        else
          render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/appointments/rep_sample_appointment', 
            locals: {require_appointment: false, drugs: drugs}, :layout => false, :formats => [:html])}
          return
        end        
      else
        raise "Opening model view without passing is_modal=true"
      end
    else
      get_my_offices
      render :index
    end
  end

  def deliver_samples
    @record.update(:samples_delivered_at => Time.now)
    flash[:success] = "Samples marked as delivered!"
    redirect_back(fallback_location: root_path)
  end

  def confirm

    @appointment = Appointment.find(params[:id])
    @appointment.confirm_for_rep!
    @appointment.update(:updated_by_id => @modifier_id)

    if @xhr
      render json: { template: (render_to_string :partial => 'rep/calendars/components/sales_rep_appointment', locals: {appointment: @appointment, user: current_user}, :layout => false, :formats => [:html]) }
    else
      flash[:success] = "Appointment has been confirmed!"
      if params[:office_view] == "true"
        redirect_to rep_offices_path(id: @appointment.office.id)
      else
        redirect_to current_rep_calendars_path
      end
    end

  end

  def book_standby
    @record = Appointment.where(id: params[:id]).first
    redirect_to "/404" if !@record
    if @record && @record.cancelled_at.present? && @record.standby_filled?
      @standby_filled = true
    else
      @appointment = Appointment.fill_standby(@record, current_user.sales_rep, true)
      unless @appointment
        flash[:error] = "There was an error processing your request! Please contact us for assistance."
        redirect to current_rep_calendars_path
      end
    end
  end

  def cancel_confirm    
    @appointment.rep_confirmed_at = nil
    @appointment.save

    render json: { template: (render_to_string :partial => 'rep/calendars/components/sales_rep_appointment', locals: {appointment: @appointment, user: current_user}, :layout => false, :formats => [:html])
                  }

  end

  #order history
  #used to display list of appts that meet criteria of order.appointment to be re-ordered
  def reorder_meal
    appointments = current_user.sales_rep.upcoming_appointments_for_reorder(@record)
    order = Order.find(params[:order_id])
    render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/appointments/rep_appointments_for_reorder',
     locals: {appointments: appointments, order: order}, :layout => false, :formats => [:html])}
    return
  end

  def cancel
    form = Forms::FrontendAppointment.new(current_user, allowed_params, @record, @modifier_id)
    order = @record.active_order
    unless form.cancel("space_sales_rep")
      render :json => {success: false, general_error: "Unable to cancel appointment due to the following errors or notices:", errors: form.errors}, status: 500
      return
    end

     # Model validations & save
    unless form.save
      render :json => {success: false, general_error: "Unable to cancel appointment at this time due to a server error.", errors: form.errors}, status: 500
      return
    end

    flash[:success] = "Appointment has been canceled!"
    if params[:office_view] == "true"
      redirect_to rep_offices_path(id: @record.office.id)
    else
      redirect_to current_rep_calendars_path
    end

  end

  def select_restaurant
    if !@appointment.active? && !@appointment.non_lp?
      redirect_to rep_appointment_path(@appointment)
    elsif @appointment.active_order
      redirect_to select_food_rep_appointment_path(@appointment)
    elsif @appointment.is_sample? || !@appointment.upcoming?
      redirect_to current_rep_calendars_path
    end
      
    @office = @appointment.office

    if @appointment.recommended_cuisines.present?
      @restaurants = Appointment::FilteredRestaurants.new(@office, {:cuisines => [@appointment.recommended_cuisines.to_a]}, @appointment, current_user,
        session[:impersonator_id].present?).filtered
    else
      @restaurants = @office.filtered_available_restaurants(@appointment, current_user, session[:impersonator_id].present?)
    end 
    #default sort  relevance
    @restaurants = Managers::SortManager.new(Restaurant, @restaurants, "relevance", current_user.sales_rep).results
    #grab most recent order, and most recent_order_review
    
    if @appointment.non_lp?
      @recent_order = current_user.sales_rep.recent_past_order_non_lp(@office, @appointment)
    else
      @recent_order = current_user.sales_rep.recent_past_order(@office, @appointment)
    end
    @recent_order_review = @recent_order.active_rep_review(current_user) if @recent_order

    @past_order = @office.recent_order(@appointment) if !@recent_order
  end

  #expects a param with a list of the currently filtered restaurant ids, to minimize time it takes to sort
  def sort_restaurants
    sort_by = "relevance"
    sort_by = params[:sort_by] if params[:sort_by].present?
    restaurants = Restaurant.where(id: params[:restaurant_ids]) if params[:restaurant_ids].present?
    return if !restaurants.present?
    @sort_manager = Managers::SortManager.new(Restaurant, restaurants, sort_by, current_user.sales_rep)

    restaurants = @sort_manager.results

    render json: {templates: {
                    targ__restaurant_list: (render_to_string :partial => 'rep/appointments/components/filtered_restaurants_list', locals: {appointment: @record, restaurants: restaurants}, :layout => false, :formats => [:html])
                    }
                  }
  end

  ##TOO DO add logic for exact order recommendations **
  def select_food
    redirect_to current_rep_calendars_path and return if (@appointment.active_order && 
      !@appointment.active_order.restaurant_editable? && !session[:impersonator_id].present? ) || @appointment.is_sample?
    session[:cart] ||= []
    cached_order = nil
    @edit_in_progress = false
    # If the user changes the restaurant, clear out the cart
    if @appointment.current_order && params[:restaurant_id].present? && @appointment.restaurant && @appointment.restaurant_id != params[:restaurant_id].to_i
      order = @appointment.current_order
      order.update(:updated_by_id => @modifier_id)
      order.line_items.update(:status => 'deleted')
      order.update_total
    end

    if params[:restaurant_id].present?
      @appointment.update(restaurant_id: params[:restaurant_id])
    end
    @restaurant = @appointment.restaurant

    @order = @appointment.current_order || Order.start(appointment_id: @appointment.id, restaurant_id: @restaurant.id, 
      :created_by_user_id => @modifier_id, :updated_by_id => @modifier_id)
    if @order.active?
      if !session[:cart].select{|order| order['order_id'] == @order.id}.any?
        cached_order = {:order_id => @order.id, :line_items => @order.line_items.active.pluck(:id)}
        session[:cart] << {:order_id => @order.id, :line_items => @order.line_items.active.pluck(:id)}
      else
        cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
      end
    end
    if cached_order && cached_order['line_items']
      @line_items = LineItem.find(cached_order['line_items']) 
      @edit_in_progress = true if @order.line_items.active.pluck(:id) != @line_items.pluck(:id)
    else
      @line_items = @order.line_items.active
    end
    @menus = @restaurant.filtered_menus_by_time(@appointment.starts_at)


    @total_count = @order.appointment.appointment_slot.total_staff_count if @order.appointment.appointment_slot
    unless @order.id
      puts @order.errors.full_messages
      raise "Order failed to save"
    end

    @order.update(:restaurant_id => @appointment.restaurant_id)

    @office = @appointment.office

  end

  #create a duplicate of the order recommendation, and assign it to the appointment, so the rep can manipulate how they see fit
  def order_recommendation
    new_order = Order.create_order_from_recommendation(@record.recommended_order, current_user) if @record.recommended_order
    if new_order
      redirect_to select_food_rep_appointment_path(@record, :restaurant_id => new_order.restaurant_id)
    else
      redirect_to current_rep_calendars_path
    end
  end

  def add_food

  end

  def byo
    if @xhr
      if modal?
        @redirect_to = params[:redirect_to]
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/appointments/rep_byo', :layout => false, :formats => [:html]) }
        return
      else
        redirect_to current_rep_calendars_path
      end
    else
      redirect_to current_rep_calendars_path
    end
    return
  end

  def show_existing
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/rep_show_existing_appointment', locals: {appointment: @record}, :layout => false, :formats => [:html]) }
        return
      else
        redirect_to current_rep_calendars_path
      end
    else
      redirect_to current_rep_calendars_path
    end
    return
  end

  def prompt_schedule
    if @xhr
      if modal?
        @office = Office.find(params[:office])
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/rep_prompt_schedule_appointment', locals: {office: @office}, :layout => false, :formats => [:html]) }
        return
      else
        redirect_to current_rep_calendars_path
      end
    else
      redirect_to current_rep_calendars_path
    end
    return
  end

  def display_duplicate
    office = Office.find(params[:office_id])
    appointment_slot = AppointmentSlot.find(params[:slot_id])
    if @xhr
      if modal?
        @modal = true
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/appointments/rep_display_duplicate_appointment', 
          locals: {
            office: office,
            appointment_slot: appointment_slot,
            date: params[:date]}, 
          :layout => false, :formats => [:html]) }
        return
      else
        @modal = false
        redirect_to current_rep_calendars_path
      end
    else
      redirect_to current_rep_calendars_path
    end
    return
  end

  def display_booked
    if @xhr
      if modal?
        @modal = true
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/appointments/rep_display_booked_appointment', locals: {appointment: @record}, :layout => false, :formats => [:html]) }
        return
      else
        @modal = false
        redirect_to current_rep_calendars_path
      end
    else
      redirect_to current_rep_calendars_path
    end
    return
  end


  def filter_restaurants
    @office = @appointment.office

    @restaurants = Appointment::FilteredRestaurants.new(@office, params.permit(:cuisines => [], :price_range => []), @appointment, current_user,
      session[:impersonator_id].present?).filtered

    render json: { template: (render_to_string :partial => 'rep/appointments/components/filtered_restaurants', locals: {restaurants: @restaurants}, :layout => false, :formats => [:html]) }

  end

  def get_my_offices
    @offices = []
    @offices = current_user.sales_rep.active_offices
  end

  def get_active_offices
    @active_offices = Office.where.not(id: current_user.sales_rep.offices_sales_reps.active.pluck(:office_id), internal: false).active
  end

  private
  def allowed_params
    groupings = [:appointment, :user, :office, :sales_rep]

    super(groupings, params)
  end
end
