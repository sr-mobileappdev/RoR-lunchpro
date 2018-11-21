class Forms::Api::FormOfficesSalesRep
  attr_reader :errors

	def initialize(offices_sales_rep)
		@rep = offices_sales_rep
		@errors = []
	end
	
	def valid?
		unless @rep.valid?
			@errors += @rep.errors.full_messages
		end
		
		if (@rep.new_record? && OfficesSalesRep.find_by(:sales_rep_id => @rep.sales_rep_id, :office_id => @rep.office_id, :status => 1) != nil)
			@errors << "An active association between this sales rep and office already exists"
		end
		
		return (@errors.count == 0)
	end
	
	def save?
		success = false
		
		ActiveRecord::Base.transaction do
			if !@rep.save
				raise ActiveRecord::Rollback
			else
				success = true
			end
		end
		
		return success
	end
	
	def soft_delete?
	
	cancelled_children = false
	ActiveRecord::Base.transaction do
		future_appts = Appointment.select{|appt| appt.active? && appt.sales_rep_id == @rep.sales_rep_id && appt.office_id == @rep.office_id && appt.appointment_time(true) > Time.now.in_time_zone(@rep.office.timezone)}
			future_appts.each do |future_appt|
			future_appt.assign_attributes(:status =>Constants::STATUS_INACTIVE, :cancelled_at => Time.now.utc)
			if !future_appt.save
				raise ActiveRecord::Rollback
			end
			if future_appt.orders.present?
				future_appt.orders.each do |order|
					order.assign_attributes(:status => Constants::STATUS_INACTIVE)
					if !order.save
						raise ActiveRecord::Rollback
					end
					begin
						order.line_items.where.not(:status => Constants::STATUS_DELETED).each do |line_item|
  							line_item.update_attributes!(:status => Constants::STATUS_DELETED)
  						end
  					rescue
						raise ActiveRecord::Rollback
  					end
				end
			end
		end
		cancelled_children = true
	end
	
	
	if cancelled_children
		@rep.status = 9
		return @rep.save
	end
	end
  
end