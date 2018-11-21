class Api::V1::OrdersController < ApiController
  include SwaggerBlocks::Orders
  
  before_action :set_record, only: [:update, :show, :destroy]
  skip_before_action :check_user_space, only: [:create, :index]
  
  def set_record
  	@order = Order.find(params[:id])
  end
    
  def index
    records = []
    
    if params[:last_order_appointment_id].present?
    	appt = Appointment.find(params[:last_order_appointment_id])
    	office = appt.office
    	sales_rep = appt.sales_rep
    	latest_order = sales_rep.recent_past_order(office,appt)
    	if latest_order.present?
    		records << latest_order.as_json(:include => parsed_include_params, :except => ["appointment"]).merge({ appointment: latest_order.appointment.as_json(:methods => ["upcoming_order?"], :except => ["starts_at","ends_at"]).merge(:starts_at => latest_order.appointment.appointment_time(true), :ends_at => latest_order.appointment.appointment_end_time(true)) })
    	end
    	render json: records and return
    elsif params[:sales_rep_id].present?
    	if params[:slot_type].present? && params[:office_id].present?
    		Order.active.where(:sales_rep_id => params[:sales_rep_id]).each do |order|  
    			if(order.appointment.present? && order.appointment.appointment_slot.present? && order.appointment.office_id.present?)  	    				
    				if(order.appointment.office_id.to_s == params[:office_id] && order.appointment.appointment_slot.slot_type == params[:slot_type])
    					records << order
    				end
    			end
    		end
    	else
    		records = Order.active.where(:sales_rep_id => params[:sales_rep_id])
    	end
    else
    	records = Order.active
    end

    render json: records.to_json(:include => parsed_include_params) and return
  end
  
  def show
	total_staff_count = (@order.appointment.appointment_slot.present? ? @order.appointment.appointment_slot.total_staff_count : nil)
	render json: @order.as_json(:include => parsed_include_params, :methods => ["is_past_order","editable?","restaurant_editable?","authorized?","cancellable?"], :except => ["appointment"])
	.merge({payment_method: @order.payment_method, appointment: @order.appointment.as_json(:methods => ["upcoming_order?"], :except => ["starts_at","ends_at"]).merge(:starts_at => @order.appointment.appointment_time(true), :ends_at => @order.appointment.appointment_end_time(true), :total_staff_count => total_staff_count, :diet_restrictions => @order.appointment.diet_restrictions_api, :office => @order.appointment.office)}) and return
  end
  
  def destroy
  	form = Forms::Api::FormOrder.new(@order)
  	unless form.soft_delete?
  		render :json => { success: false, message: "An error occurred while trying to cancel the order.", errors: form.errors }, status: 500
  	end
  	render json: { success: true, message: "Successfully cancelled the order." } and return
  end

  def create
  if params[:repeat_order_id].present?
  	success = false
  	cloned_order = nil
    ActiveRecord::Base.transaction do
    	begin
    		order_to_clone = Order.find(params[:repeat_order_id])
    		order_to_clone.assign_attributes(:appointment_id => params[:appointment_id])
  			cloned_order = Order.create_order_from_recommendation(order_to_clone, SalesRep.find(params[:sales_rep_id]).user)
  			cloned_order.update!(:status => Order.statuses.key(Constants::STATUS_ACTIVE))
  			appt = Appointment.find(params[:appointment_id])
  			appt.update!(:food_ordered => true, :restaurant_id => cloned_order.restaurant_id, :bring_food_notes => nil, :will_supply_food => false, :status => Appointment.statuses.key(Constants::STATUS_ACTIVE))
  			success = true
  		rescue Exception => ex
  			Rollbar.error(ex)
  			raise ActiveRecord::Rollback
  		end
  	end
  	if success
	  	render json: { success: true, message: "Successfully repeated the order.", order: cloned_order } and return
	else
		render json: { success: false }, status: 500 and return
	end
  else
  
  #create records
  order_to_create = Order.new(:status => Constants::STATUS_ACTIVE)
  order_to_create.assign_attributes(create_params)
  line_items = get_line_items_from_request(params, order_to_create)

  form = Forms::Api::FormOrder.new(order_to_create, line_items)
  #validate records  	
  	unless form.valid?
  		render :json => {success: false, message: "Unable to create new order due to the following errors or notices:", errors: form.errors}, status: 400
      	return
  	end
  	
  #save records
  	unless form.save
      render :json => {success: false, message: "Unable to create new order at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    
    Managers::NotificationManager.trigger_notifications([203], [order_to_create, order_to_create.restaurant, order_to_create.appointment, order_to_create.appointment.office, order_to_create.appointment.appointment_slot, order_to_create.sales_rep]) 
    
  #return created record
	render json: { success: true, message: "Successfully created a new order.", order: order_to_create } and return
  end
  end
  
  def update
  	previous_tip = @order.tip_cents
  	@order.assign_attributes(update_params)
  	line_items = get_line_items_from_request(params, @order)

  	form = Forms::Api::FormOrder.new(@order, line_items)
  	
  #validate records  	
  	unless form.valid?
  		render :json => {success: false, message: "Unable to update the order due to the following errors or notices:", errors: form.errors}, status: 400
      	return
  	end
  #save records
  	unless form.save
      render :json => {success: false, message: "Unable to update the order at this time due to a server error.", errors: form.errors}, status: 500
      return
    end
    
    if !@order.is_past_order
    	@order.appointment.update(:restaurant_confirmed_at => nil)
	    Managers::NotificationManager.trigger_notifications([207], [@order, @order.restaurant, @order.appointment, @order.appointment.sales_rep, @order.appointment.office])
	elsif @order.editable?
		Managers::NotificationManager.trigger_notifications([211], [@order, @order.restaurant, @order.appointment, @order.appointment.sales_rep, @order.appointment.office], {previous_tip_amount: previous_tip})
	end
    
    #return updated record
	render json: { success: true, message: "Successfully updated the order.", order: @order } and return
  end
  
  private
  def get_line_items_from_request (order_from_request, active_record_order)
  	line_items = []
  	if order_from_request[:line_items].present? && order_from_request[:line_items].kind_of?(Array)
  		order_from_request[:line_items].each do |line_item|
  			ar_line_item = LineItem.new(:orderable_type => "MenuItem", :order => active_record_order, :status => Constants::STATUS_ACTIVE, :created_at => Time.now.utc, :updated_at => Time.now.utc)
  			ar_line_item.assign_attributes(:name => line_item[:name], :quantity => line_item[:quantity], :notes => line_item[:notes], :orderable_id => line_item[:orderable_id], :people_served => line_item[:people_served], :category => line_item[:category], :unit_cost_cents => line_item[:unit_cost_cents])
  			ar_line_item.assign_attributes(:cost_cents => (ar_line_item[:quantity].present? ? ar_line_item[:quantity] : 0) * (ar_line_item[:unit_cost_cents].present? ? ar_line_item[:unit_cost_cents] : 0))
  			if line_item[:sub_line_items].present? && line_item[:sub_line_items]
  				line_item[:sub_line_items].each do |sub_line_item|
  					ar_sub_line_item = LineItem.new(:orderable_type => "MenuSubItemOption", :order => active_record_order, :status => Constants::STATUS_ACTIVE, :created_at => Time.now.utc, :updated_at => Time.now.utc)
  					ar_sub_line_item.assign_attributes(:name => sub_line_item[:name], :orderable_id => sub_line_item[:orderable_id], :quantity => ar_line_item.quantity, :unit_cost_cents => sub_line_item[:unit_cost_cents])
  					ar_sub_line_item.assign_attributes(:cost_cents => (sub_line_item[:unit_cost_cents].present? ? sub_line_item[:unit_cost_cents] : 0) * (ar_line_item.quantity.present? ? ar_line_item.quantity : 0))
  					ar_line_item.sub_line_items << ar_sub_line_item
  				end
  			end  	
  			line_items << ar_line_item
  		end  		
  	end
  	return line_items
  end
  
  def update_params
  	params.require(:order).permit(:sales_rep_id, :appointment_id, :restaurant_id, :rep_notes, :tip_cents, :payment_method_id)
  end
  
  def create_params
  	params.permit(:sales_rep_id, :appointment_id, :restaurant_id, :rep_notes, :tip_cents, :payment_method_id)
  end
end
