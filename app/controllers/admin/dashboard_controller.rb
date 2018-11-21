class Admin::DashboardController < AdminController
  before_action :set_location
  before_action :set_order, only: [:confirm_order, :cancel_order]
  before_action :set_appointment, only: [:confirm_app, :cancel_app, :byo, :update_byo, :cancel_popup, :order_food, :activate_user]

  def set_location
    if params[:location]
      @location = params[:location]
    else
      @location = 'Austin'
    end

  end

  def set_order
    @order = Order.find(params[:id])
  end

  def set_appointment
    @appointment = Appointment.find(params[:id])

  end

  def index
    #redirect_to admin_users_path
    @weekdays = {"Monday" => 0, "Tuesday" => 1, "Wednesday" => 2, "Thursday" => 3, "Friday" => 4}
    @weeks_ago = [1,2,3,4,5]
  end

  def activity
    
    #redirect_to admin_users_path
    # WANTS ANY PAST UNCONFIRMED + TODAY, TOMORROW, DAY AFTER TOMORROW
    @unconfirmed_orders = Order.unconfirmed_by_location(@location).sort_by{|o| [o.appointment.appointment_on, o.appointment.starts_at]}
    @appointments = Appointment.unconfirmed_by_location(@location).sort_by{|a| [a.appointment_on, a.starts_at]}
    @todays_events = Appointment.for_today(@location).sort_by{|a| [a.appointment_on, a.starts_at]}
    @confirmed_apps_wo_food = Appointment.confirmed_without_food_by_location(@location).sort_by{|a| [a.appointment_on, a.starts_at]}
    @w_cancelled_order = Appointment.with_declined_by_location(@location).sort_by{|a| [a.appointment_on, a.starts_at]}
  end

  def cancel_popup
    if @xhr
      render json: { html: (render_to_string :partial => 'cancel_popup', :layout => false, :formats => [:html]) }
      return
    else
      head :ok
    end
  end

  def confirm_order
    unless @order.appointment.confirm_for_restaurant!
      render json: {success: false, general_error: "Unable to confirm this order at this time due to a server error", errors: []}, status: 500
    end

    flash[:notice] = "Order Number '#{@order.order_number}' has been confirmed"
    redirect_to activity_admin_dashboard_index_path(location: @location)
  end

  def cancel_order
    @order.restaurant_cancelled = true      #virtual attr to bypass order notif triggers
    @order.update_attributes(status: 'inactive', updated_by_id: current_user.id, cancelled_at: Time.now, cancelled_by_id: current_user.id)
    @order.appointment.update_attributes(restaurant_confirmed_at: nil)
    restaurant = @order.restaurant_transactions
    Managers::NotificationManager.trigger_notifications([301],
      [restaurant, @order, @order.appointment, @order.appointment.office], {poc: current_user.poc_info})

    flash[:alert] = "Order has been canceled"
    redirect_to activity_admin_dashboard_index_path(location: @location)
  end

  def confirm_app
    @appointment.assign_attributes(:rep_confirmed_at => Time.now, :office_confirmed_at => Time.now, :updated_by_id => current_user.id)
    @appointment.save(validate: false)

    flash[:notice] = "Appointment has been confirmed for #{@appointment.sales_rep.display_name}"
    redirect_to activity_admin_dashboard_index_path(location: @location)
  end

  def cancel_app
    if params[:cancel_reason].present?
      @appointment.update_attributes(cancel_reason: params[:cancel_reason], cancelled_at: Time.now, status: "inactive", cancelled_by_id: current_user.id)
    else
      flash[:alert] = "You must enter a cancellation reason"
    end

    flash[:notice] = 'Appointment has been cancelled'
    redirect_to activity_admin_dashboard_index_path(location: @location)
  end

  def order_food
    if @xhr
      if @appointment.user_activated?
        render json: { html: (render_to_string partial: 'order_selection', layout: false, formats: [:html]) }
        return
      else
        render json: { html: (render_to_string partial: 'activate_user', layout: false, formats: [:html]) }
        return
      end
    else
      head :ok
    end
  end

  def byo
    if @xhr
      render json: { html: (render_to_string partial: 'byo_form', layout: false, formats: [:html]) }
      return
    else
      head :ok
    end
  end

  def update_byo
    if params[:appointment][:bring_food_notes]
      @appointment.update_attributes(allowed_params[:appointment])
      @appointment.update_attributes(will_supply_food: true)
    end

    flash[:notice] = "Appointment has been updated. #{@appointment.sales_rep.display_name} will be bringing food from #{@appointment.bring_food_notes}."
    redirect_to activity_admin_dashboard_index_path(location: @location)
  end

  def activate_user
    rep = @appointment.sales_rep
    rep.update_attributes(activated_at: Time.now, status: 'active')
    rep.user.update_attributes(validated_at: Time.now, validated_by_id: current_user.id, last_modified_at: Time.now, last_modified_by_id: current_user.id, invitation_accepted_at: Time.now)

    flash[:notice] = "#{@appointment.sales_rep.display_name} has been activated. You can now impersonate and order food for them."
    redirect_to activity_admin_dashboard_index_path(location: @location)
  end

  private
    def allowed_params
      groupings = [:appointment]

      super(groupings, params)
    end

end
