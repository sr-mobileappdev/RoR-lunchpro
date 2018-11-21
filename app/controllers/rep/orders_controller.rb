class Rep::OrdersController < ApplicationRepsController

  before_action :set_order, only: [:show, :review, :menu, :confirm, :cancel, :reorder, :update, :download, :print, :undo_changes, :select_item,
  :edit_item, :add_item, :update_item, :remove_item, :complete_order, :payment, :save_payment]
  before_action :set_payment_manager, only: [:save_payment]

  before_action :check_order, only: [:select_item, :edit_item, :add_item, :update_item, :remove_item, :payment, :save_payment,
    :confirm, :complete, :complete_order]

  before_action :set_modifier_id

  def set_modifier_id
    @modifier_id = session[:impersonator_id] || current_user.id
  end


  def check_order
    #redirect_to current_office_calendars_path if @order && !@order.restaurant_editable?
  end

  def set_order
    @order = Order.where(id: params[:id]).first
    redirect_to "/404" if !@order || !@order.belongs_to?(current_user.sales_rep)
  end

  def set_payment_manager
    @payment_manager = Managers::PaymentManager.new(current_user, nil, nil)
  end
  # List of reps orders
  def index
    @time_range = (Time.now.beginning_of_month.to_date..Time.now.to_date)

    @slot_manager = Views::SalesRepAppointments.new(current_user.sales_rep, @time_range, current_user)
    if params[:id]
      order = Order.where(id: params[:id]).first
      @order_id = order.id if order && order.belongs_to?(current_user.sales_rep) && !order.inactive?
    else
      begin
        @order_id = @slot_manager.past_orders.first.second.sort_by{|appt| appt.starts_at(true)}.first.orders.first.id
      rescue => ex

      end
    end
  end

  def new
    get_my_offices
  end

  def reorder
    appointment = Appointment.find(params[:appointment_id]) if params[:appointment_id].present?
    raise "Must Provide an Appointment" if !appointment

    form = Forms::FrontendOrder.new(current_user, params, @order, appointment)

    unless form.reorder
      render :json => {success: false, general_error: "Unable to create order due to the following errors:", errors: form.errors}, status: 500
      return
    end

    redirect_to select_food_rep_appointment_path(appointment)
  end

  # Individual office detail view
  def show
    if @order
      @rep_order_review = @order.active_rep_review(current_user) || OrderReview.new
      @office_order_review = @order.active_review('Office')
      appointment = Appointment.find(params[:current_appointment_id]) if params[:current_appointment_id].present?
    end
    if @xhr
      if modal?
        render json: { html: (render_to_string :partial => 'shared/modals/sales_reps/orders/' + @order.rep_order_modal(params[:most_recent_order]), locals:{redirect: params[:redirect_to], appointment: appointment}, :layout => false, :formats => [:html]) }
      else
        render json: {templates: {
                          targ__order_detail: (render_to_string :partial => "rep/orders/components/order_detail", :layout => false, :formats => [:html])
                        }
                      }
      end
    else

      redirect_to current_rep_calendars_path and return if !@order.active? && !@order.completed?
    end
  end

  def update
    tip = nil
    if params[:order][:tip_cents].present?
      tip  = params[:order][:tip_cents].to_f
      tip *= 100
    end
    previous_tip = @order.tip_cents
    if (@order.total_cents - previous_tip + tip) > @order.authorized_amount_cents(true)
      render :json => {success: false,
        general_error: "The order total cannot exceed the authorized amount of #{ApplicationController.helpers.precise_currency_value(@order.authorized_amount_cents)}!"},
        status: 500
      return
    end
    unless @order.update(:tip_cents => tip, :updated_by_id => @modifier_id)
      render :json => {success: false, general_error: "Unable to update  order due to the following errors or notices:", errors: @order.errors}, status: 500
      return
    end
    @order.update_total(current_user)
    if @order.is_past_order
      Managers::NotificationManager.trigger_notifications([211], [@order, current_user.sales_rep, @order.restaurant, @order.appointment.office], {previous_tip_amount: previous_tip})
    end
    flash[:success] = "Order has been updated!"

    if params[:redirect_to].present?
      redirect_path = rep_orders_path(order: @order.id)
    else
      redirect_back(fallback_location: root_path) and return
    end
    redirect_to redirect_path and return
  end


  def cancel
    #if order is with a non lp office, delete the appointment
    @appointment = @order.appointment

    if (!@order.appointment.appointment_slot && @order.update(:status => 'inactive', :updated_by_id => @modifier_id, :cancelled_at => Time.now, :cancelled_by_id => @modifier_id) && @order.appointment.update(:food_ordered => false, :restaurant_id => nil)) ||
       (@order.appointment.appointment_slot && @order.update(:status => 'inactive', :updated_by_id => @modifier_id, :cancelled_at => Time.now, :cancelled_by_id => @modifier_id) && @order.appointment.update(:food_ordered => false, :restaurant_id => nil))
      @order.line_items.update_all(:status => 'deleted')

      flash[:success] = "Order has been canceled!"
      if params[:redirect_to].present?
        redirect_to_tab(params[:redirect_to], @order.appointment.office.id)
      elsif params[:office_view] == "true"
        redirect_to rep_offices_path(id: @order.appointment.office.id)
      else
        redirect_back(fallback_location: root_path)
      end
    else
      render :json => {success: false, general_error: "Unable to cancel order due to the following errors or notices:", errors: @order.errors}, status: 500
      return
    end
  end

  #used to show a single menu and it's items from order flow
  def menu
    if @xhr
      partial = 'rep/appointments/components/filtered_menu_items'

      #nil menu == full menu
      menu = nil
      if params[:menu_id].present?
        menu = Menu.find(params[:menu_id])
      end
      restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id].present?
      raise "Unable to find restaurant with the provided ID" unless restaurant
      render json: {templates: {
          targ__filtered_menu_items: (render_to_string :partial => partial, locals:{restaurant: restaurant, menu: menu}, :layout => false, :formats => [:html])
        }
      }
    else
    end
  end

  def policies
    if params[:appointment_id].present?
      @appointment = Appointment.find(params[:appointment_id])
      redirect_to current_rep_calendars_path and return if !@appointment.present?
    end

    @office = @appointment.office

    if params[:order_id].present?
      @order = Order.where(id: params[:order_id]).first
      redirect_to "/404" and return if !@order || !@order.belongs_to?(current_user.sales_rep)
      @reorder = true
      redirect_to current_rep_calendars_path and return if !@order.present? || !@office.present?
    end
  end

  def select_item # Popup to select and add details for an item, to an order
    if @xhr
      item = MenuItem.find(params[:menu_item_id])
      @url = add_item_rep_order_path(@order)
      @line_item = LineItem.new(orderable: item, quantity: 1)

      render json: { html: (render_to_string :partial => 'rep/orders/components/select_item', locals: {item: item, order: @order, user: current_user}, :layout => false, :formats => [:html])
                    }
    else
      redirect_to request.referrer
    end

  end

  def edit_item

    @line_item = LineItem.find(params[:line_item_id])
    @url = update_item_rep_order_path(@order, line_item_id: @line_item.id)
    render json: { html: (render_to_string :partial => 'rep/orders/components/edit_item', locals: {line_item: @line_item, order: @order, user: current_user}, :layout => false, :formats => [:html])
                  }
  end

  def add_item # Adds an item to an existing order

    appointment = @order.appointment

    @line_item = LineItem.new(line_item_params)
    @line_item.order_id = @order.id

    menu_item = MenuItem.find(params[:line_item][:orderable_id])

    sub_option_ids = params[:menu_item_sub_options] || []
    sub_item_options = MenuSubItemOption.where(id: sub_option_ids)

    sub_items = menu_item.menu_sub_items.active
    sub_items.each do |si|
      if si.qty_required > 0
        unless sub_item_options.select{|opt| si.menu_sub_item_options.include?(opt)}.count >= si.qty_required
          flash[:error] = "#{si.menu_item.name} - Must select at least #{si.qty_required} option(s) for #{si.name}"
          redirect_to select_food_rep_appointment_path(appointment)
          return
        end
      end
    end

    @line_item.cost_cents = @line_item.orderable.retail_price_cents.to_i * (@line_item.quantity || 1)
    @line_item.unit_cost_cents = @line_item.orderable.retail_price_cents.to_i
    @line_item.created_by = current_user
    @line_item.people_served = menu_item.people_served
    @line_item.category = menu_item.category
    if @order.active? && session[:cart].select{|order| order['order_id'] == @order.id}.any?
      @line_item.status = 'draft'
      @line_item.save!
      @cached_order  = session[:cart].select{|order| order['order_id'] == @order.id}.first
      @cached_order['line_items'] << @line_item.id
    else
      @line_item.save!
    end

    sub_item_options.each do |option|
      if @cached_order
        status = "draft"
      else
        status = "active"
      end
      sub_option_params = { order_id: @order.id,
                            quantity: @line_item.quantity,
                            orderable_id: option.id,
                            orderable_type: 'MenuSubItemOption',
                            cost_cents: (@line_item.quantity || 1) * (option.price_cents || 0),
                            unit_cost_cents: (option.price_cents || 0),
                            created_by: current_user,
                            parent_line_item_id: @line_item.id,
                            status: status }

      item = LineItem.new(sub_option_params)
      item.save!
      @cached_order['line_items'] << item.id if @cached_order
    end
#    @order.update_total

    redirect_to select_food_rep_appointment_path(appointment)

  end

  def update_item
    return_path = params[:return_path] || 'select_food'

    appointment = @order.appointment

    @line_item = LineItem.find(params[:line_item_id])

    if @line_item.orderable_type == 'MenuItem'
      menu_item = MenuItem.find(params[:line_item][:orderable_id])
      sub_option_ids = params[:menu_item_sub_options] || []
      sub_item_options = MenuSubItemOption.where(id: sub_option_ids)

      sub_items = menu_item.menu_sub_items.active
      sub_items.each do |si|
        if si.qty_required > 0
          unless sub_item_options.select{|opt| si.menu_sub_item_options.include?(opt)}.count >= si.qty_required
            flash[:error] = "#{si.menu_item.name} - Must select at least #{si.qty_required} option(s) for #{si.name}"
            redirect_to select_food_rep_appointment_path(appointment)
            return
          end
        end
      end
    end

    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    status = nil
    if cached_order
      cached_order['line_items'].delete(params[:line_item_id].to_i)
      cached_order['line_items'].reject! {|item| @line_item.sub_line_items.pluck(:id).include?(item) }
      @line_item = LineItem.new(@line_item.attributes.except("id", "created_at", "updated_at"))
      status = 'draft'
    else
      status = 'active'
    end

    if @line_item.update(line_item_params)
      @line_item.cost_cents = @line_item.orderable.retail_price_cents.to_i * (@line_item.quantity || 1)
      @line_item.unit_cost_cents = @line_item.orderable.retail_price_cents.to_i
      @line_item.status = status
      if @line_item.save
        sub_option_ids = params[:menu_item_sub_options] || []
        sub_item_options = MenuSubItemOption.where(id: sub_option_ids)
        new_sub_items = []
        sub_item_options.each do |option|
          sub_option_params = { order_id: @order.id,
                                quantity: @line_item.quantity,
                                orderable_id: option.id,
                                orderable_type: 'MenuSubItemOption',
                                cost_cents: (@line_item.quantity || 1) * (option.price_cents || 0),
                                unit_cost_cents: (option.price_cents || 0),
                                created_by: current_user,
                                parent_line_item_id: @line_item.id,
                                status: status }

          new_sub_items << LineItem.new(sub_option_params)

        end

        #### too doo, delete line items wrap in rollback ####
        ActiveRecord::Base.transaction do
          if @line_item.sub_line_items.update_all(:status => 'deleted')
            @line_item.sub_line_items << new_sub_items
            cached_order['line_items'] << @line_item.id if cached_order
            cached_order['line_items'] += new_sub_items.pluck(:id) if cached_order
          else
            raise ActiveRecord::Rollback
          end
        end
      end
     # @order.update_total
    else

    end

    if return_path == "select_food"
      redirect_to select_food_rep_appointment_path(appointment)
    elsif return_path == "confirm"
      redirect_to confirm_rep_order_path(@order)
    end

  end

  def undo_changes
    @order.line_items.where(:status => 'draft').update(:status => 'deleted')
    @order.update_total(current_user)
    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    session[:cart].delete(cached_order) if cached_order

    redirect_to select_food_rep_appointment_path(@order.appointment)
  end

  def download
    respond_to do |format|
      format.csv do
        man = Managers::CsvManager.new
        csv_data = man.generate_order_detail(@order)
        unless !man.errors.any?
          flash[:warning] = "There was an error processing your request. Please contact customer support for assistance."
          redirect_to rep_orders_path(order: @order.id) and return
        end
        send_data csv_data,
              :type => 'text/csv',
              :disposition => "attachment; filename=Order_#{@order.order_number}.csv"
      end
      format.pdf do
        if @order
          @rep_order_review = @order.active_rep_review(current_user) || OrderReview.new
          @office_order_review = @order.active_review('Office')
          appointment = Appointment.find(params[:current_appointment_id]) if params[:current_appointment_id].present?
        end
        ah = ApplicationController.helpers
        pdf = WickedPdf.new.pdf_from_string(
          render_to_string(partial: 'shared/pdf/rep_om_order_detail', :layout => 'pdf', locals:{order: @order, ah: ah}, :formats => [:html]))
        send_data pdf, filename: "Order_#{@order.order_number}.pdf", type: "application/pdf", :disposition => 'inline'
      end
    end
  end


  def print
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(partial: 'shared/pdfs/rep_om_order_detail', :layout => 'pdf', locals:{order: @order}, :formats => [:html]))
=begin
    tempfile = Tempfile.new(["#{@modifier_id}_#{@order.order_number}_#{Time.now.to_i}", ".pdf"], Rails.root.join('tmp'))
    tempfile.binmode
    tempfile.write pdf
    tempfile.close

    system("lpr", tempfile.path)
    tempfile.unlink

    pdf = WickedPdf.new.pdf_from_string(
      render_to_string(partial: 'shared/pdfs/rep_om_order_detail', :layout => 'pdf', locals:{order: @order}, :formats => [:html]))
    system("lpr", "pdfs/filename.pdf")
=end
  end

  def remove_item

    return_path = params[:return_path] || 'select_food'

    appointment = @order.appointment

    @line_item = LineItem.find(params[:line_item_id])

    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    if cached_order
      cached_order['line_items'].delete(params[:line_item_id].to_i)
      cached_order['line_items'].reject! {|item| @line_item.sub_line_items.pluck(:id).include?(item) }
    else

      if @line_item.sub_line_items.count > 0
        @line_item.sub_line_items.destroy_all
      end

      @line_item.update(:status => 'deleted')

     # @order.update_total
    end

    if return_path == "select_food"
      redirect_to select_food_rep_appointment_path(appointment)
    elsif return_path == "confirm"
      redirect_to confirm_rep_order_path(@order)
    end


  end

  def payment
    redirect_to current_rep_calendars_path and return if !@order.active? && !@order.draft?
    redirect_to confirm_rep_order_path(@order) if @order.authorized? && !session[:impersonator_id].present?
    #grab list of active payment methods, or if the orders.payment_method is 'archived', grab that
    @payment_methods = @order.sales_rep.payment_methods.where(status: ["active"])
                        .or(@order.sales_rep.payment_methods.where(:id => @order.payment_method_id, :status => 'archived'))
  end

  def save_payment
    # Need to check for existing_payment_method_id.present?
    # -- if present, assign order.payment_method_id to the existing ID, and do not create any new payment method
    # -- if not present, validate and create new payment method and attach to order

    # If successful...
    payment_method_id = (params[:order][:payment_method_id].to_i if params[:order].present?) || 0
    #if they want to save a new card
    if params[:save_method].present? && payment_method_id == 0
      payment_method_id = @payment_manager.create_stripe_card(params[:card_token], params[:default], params[:order][:payment_method], true, "active")
      unless payment_method_id.present?
        render :json => {success: false, general_error: "Unable to add payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
        return
      end
    #if they dont want to save a new card, pass "archived" status to create_stripe_card so mark new payment method as archived
    elsif !params[:save_method] && payment_method_id == 0
      payment_method_id = @payment_manager.create_stripe_card(params[:card_token], params[:default], params[:order][:payment_method], true, "archived")
      unless payment_method_id.present?
        render :json => {success: false, general_error: "Unable to add payment method to sales rep due to the following errors or notices:", errors: @payment_manager.errors}, status: 500
        return
      end
    elsif params[:payment_method_id].present?
      payment_method_id = params[:payment_method_id]
    end
    @order.update!(:payment_method_id => payment_method_id, :updated_by_id => @modifier_id)
    redirect_to confirm_rep_order_path(@order)
  end

  def confirm
    redirect_to current_rep_calendars_path and return if (!@order.active? && !@order.draft?) || (@order.is_past_order)
    redirect_to payment_rep_order_path(@order) and return unless ["active", "archived"].include?(@order.payment_method.status)
    @appointment = @order.appointment
    @cached_order = nil
    if @order.active?
      @cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    end
    if @cached_order && @cached_order['line_items']
      @line_items = LineItem.find(@cached_order['line_items'])
      @cached_items = @line_items
    else
      @cached_items = nil
      @line_items = @order.line_items
    end
  end

  def complete
    @edit_order = params[:edit].present?
  end

  def complete_order
    # Save final post
    return if (!@order.active? && !@order.draft?) || (@order.is_past_order)
    @edit_order = true if @order.active?
    cached_order = session[:cart].select{|order| order['order_id'] == @order.id}.first
    if params[:order][:tip_cents].present?
      params[:order][:tip_cents] = params[:order][:tip_cents].to_f
      params[:order][:tip_cents] *= 100
    end
    @order.assign_attributes(order_params)
    @order.updated_by_id = @modifier_id
    @order.save!
    if cached_order
      @order.line_items = LineItem.find(cached_order['line_items'])
      @order.line_items.update(:status => 'active')
      session[:cart].delete(cached_order)
    else
      @order.line_items.where(:status => 'draft').update(:status => 'active')
    end
    if !@order.update_total(current_user)
      flash[:error] = @order.errors.full_messages.first
      redirect_to request.referrer and return
    end
    appointment = @order.appointment
    if appointment
      appointment.food_ordered = true
      appointment.will_supply_food = nil
      appointment.bring_food_notes = nil
      appointment.status = 'active'
      appointment.restaurant_confirmed_at = nil if @edit_order
      appointment.save

      # Trigger food ordered notifications to all parties involved
      if @edit_order
        Managers::NotificationManager.trigger_notifications([207], [@order, @order.restaurant, appointment, appointment.sales_rep, appointment.office])
      else
        # Trigger food ordered notifications to all parties involved
        #Managers::NotificationManager.trigger_notifications([203], [appointment, appointment.office, @order, appointment.sales_rep, @order.restaurant])
      end
    end


    redirect_to complete_rep_order_path(@order, edit: @edit_order)

  end

  def review
    @order_review = OrderReview.new(order_review_params)
    @order_review.status = "active"
    @order_review.reviewer_id = current_user.sales_rep.id
    @order_review.order_id = @order.id
    @order_review.reviewer_type = "SalesRep"
    @order_review.created_by_id = @modifier_id

    if params[:redirect_to] == "office"
      redirect_path = rep_offices_path(id: @order.appointment.office.id)
    elsif params[:redirect_to] == "calendar"
      redirect_path = current_rep_calendars_path
    elsif params[:redirect_to] == "show"
      redirect_path = request.referrer
    else
      redirect_path = rep_orders_path(id: @order.id)
    end

    if @order_review.save
      flash[:success] = "Order Review has been created!"
      redirect_to redirect_path
    else
      render :json => {success: false, general_error: "Unable to create order review at this time due to the following errors:", errors: @order_review.errors.full_messages}, status: 500
      return
    end
  end

  def set_delivery
    @office = Office.find(params[:office]) if params[:office].present?
    if !@office
      redirect_to new_rep_order_path and return
    end
    @record = Appointment.new(:office_id => @office.id, :origin => 'web')
  end

  def appointment_list
    @appointment_slots = current_user.sales_rep.appointments_for_orders
    render json: {
      templates: {
        targ__new_order: (render_to_string :partial => 'rep/orders/components/new_order_appointment_list', :locals =>{slots: @appointment_slots}, :layout => false, :formats => [:html])
      }
    }
  end

  def office_search
    get_my_offices
    render json: {
      templates: {
        targ__new_order: (render_to_string :partial => 'rep/orders/components/new_order_office_search_form', :locals =>{offices: @offices}, :layout => false, :formats => [:html])
      }
    }
  end

  def new_office_list
    @for_orders = true
    @office = Office.new(timezone: Constants::DEFAULT_TIMEZONE, internal: false)
    @sales_rep = current_user.sales_rep
    get_active_offices
    render json: {
      templates: {
        targ__new_order: (render_to_string :partial => 'rep/orders/components/new_order_new_offices_list', :layout => false, :formats => [:html])
      }
    }
  end

  def get_my_offices
    @offices = []
    @offices = current_user.sales_rep.active_offices.sort_by{|o| [(o.private__flag ? 1 : 0), o.name]}

  end

  def get_active_offices
    @new_offices = Office.where.not(id: current_user.sales_rep.offices_sales_reps.active.pluck(:office_id), internal: false).active
  end

private
  def order_params
    params.require(:order).permit(:status, :rep_notes, :tip_cents)
  end
  def order_review_params
    params.require(:order_review).permit(:comment, :food_quality, :presentation, :completion, :on_time, :order_id)
  end

  def line_item_params
    params.require(:line_item).permit(:quantity, :notes, :orderable_type, :orderable_id)
  end

end
