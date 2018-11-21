class Forms::Api::FormOrder
	attr_reader :errors


  def initialize(order, line_items = [])
    @order = order
    @line_items = line_items
    @errors = []
  end

  def valid?
   
    unless @order.valid?
    	@errors += @order.errors.full_messages
    end
    
    menu_items = MenuItem.where(:id => @line_items.map{ |li| li.orderable_id }).includes(:menu_sub_items)
    
    menu_sub_item_options = MenuSubItemOption.where(:id => (@line_items.map{ |li| li.sub_line_items.to_a }.flatten).map{ |sli| sli.orderable_id })
    
    @line_items.each do |parent_line_item|
    	unless parent_line_item.valid?
    		@errors += parent_line_item.errors.full_messages
    	end
    	
    	menu_sub_items = menu_items.select { |mi| mi.id == parent_line_item.orderable_id }.map{ |mi| mi.menu_sub_items.to_a }.flatten
    	
    	menu_sub_items.each do |menu_sub_item|
    		possible_menu_sub_item_options_ids = menu_sub_item_options.select{ |opt| opt.menu_sub_item_id == menu_sub_item.id }.map{ |opt| opt.id }
    		selected_menu_sub_item_options = parent_line_item.sub_line_items.select{ |opt| possible_menu_sub_item_options_ids.any?{ |possible_opt| possible_opt == opt.orderable_id }}
    		if menu_sub_item.qty_allowed.present? && selected_menu_sub_item_options.count > menu_sub_item.qty_allowed
    			@errors << "The #{menu_sub_item.name} options for #{parent_line_item.name} allows at most #{menu_sub_item.qty_allowed} options to be chosen"
    		end
    		if menu_sub_item.qty_required.present? && selected_menu_sub_item_options.count < menu_sub_item.qty_required
    			@errors << "The #{menu_sub_item.name} options for #{parent_line_item.name} requires at least #{menu_sub_item.qty_required} options to be chosen"
    		end
    	end
    	
    	parent_line_item.sub_line_items.each do |child_line_item|
    		unless child_line_item.valid?
    			@errors += child_line_item.errors.full_messages
    		end
    	end
    end

    return (@errors.count == 0)
  end

  def save
  	success = false
    ActiveRecord::Base.transaction do
    # on updates, set all previous line items to DELETED status
    	if @line_items.length > 0
    		unless @order.new_record?
    			begin
    				@order.line_items.update_all(:status => Constants::STATUS_DELETED)
    			rescue
    				raise ActiveRecord::Rollback
    			end
    		end
    	end
    	
    	restaurant = Restaurant.find(@order.restaurant_id)
    	@order.assign_attributes(:delivery_cost_cents => restaurant.default_delivery_fee_cents, :updated_by_id => @order.sales_rep.user_id)
    # save order	
    	unless @order.save
    		@errors += @order.errors.full_messages
    		raise ActiveRecord::Rollback
    	end
    	
    	order_appt = @order.appointment
    	order_appt.assign_attributes(:restaurant_id => @order.restaurant_id, :restaurant_confirmed_at => nil, :food_ordered => true, :bring_food_notes => nil, :will_supply_food => false, :status => Appointment.statuses.key(Constants::STATUS_ACTIVE))
    	
    	unless order_appt.save
    		@errors += order_appt.errors.full_messages
    		raise ActiveRecord::Rollback
    	end
    # save line items
    	@line_items.each do |line_item|
    		unless line_item.save
    			@errors += line_item.errors.full_messages
    			raise ActiveRecord::Rollback
    		end
    	end
    # update some of order's "costs" properties
    	user_record = @order.sales_rep.user
    	if user_record.present?
    		unless @order.update_total(user_record)
    			@errors += @order.errors.full_messages
		    	raise ActiveRecord::Rollback
    		end
    	else
    		unless @order.update_total
    			@errors += @order.errors.full_messages
    			raise ActiveRecord::Rollback
    		end
    	end
    	success = true
    end
    return success
  end
  
  def soft_delete?
  	success = false
  	ActiveRecord::Base.transaction do
  		begin
  			if @order.appointment.present?
  				@order.appointment.assign_attributes(:food_ordered => false, :restaurant_id => nil)
  				unless @order.appointment.save
  					@errors += @order.appointment.errors.full_messages
		  			raise ActiveRecord::Rollback
  				end
  			end
  			@order.line_items.where.not(:status => Constants::STATUS_DELETED).each do |line_item|
  				line_item.update_attributes!(:status => Constants::STATUS_DELETED)
  			end
  			@order.assign_attributes(:status => Constants::STATUS_INACTIVE)
  			unless @order.save
  				@errors += @order.errors.full_messages
	  			raise ActiveRecord::Rollback
  			end
  		rescue
  			raise ActiveRecord::Rollback
  		end
  		success = true
  	end
  	return success
  end
  
end