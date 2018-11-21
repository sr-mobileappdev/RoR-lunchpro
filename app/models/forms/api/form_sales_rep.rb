class Forms::Api::FormSalesRep
  attr_reader :errors

	def initialize(sales_rep, emails = [], phones = [], drugs = [], user_primary_phone = nil)
		@rep = sales_rep
		@errors = []
		@phones = phones
		@emails = emails
		@drugs = drugs
		@user_primary_phone = user_primary_phone
	end
	
	def soft_delete?
		success = false
			ActiveRecord::Base.transaction do
				appts = @rep.appointments.where("appointment_on > ?", Time.now)
  				orders = Order.where(:appointment_id => appts.pluck(:id))
  				
  				orders.each do |order|
					order.assign_attributes(:status => Constants::STATUS_DELETED)
					unless order.save
						raise ActiveRecord::Rollback
					end
				end
				
				appts.each do |appt|
					appt.assign_attributes(:status => Constants::STATUS_DELETED, :cancelled_by_id => @rep.user_id, :cancel_reason => "Sales rep deactivated")
					unless appt.save
						raise ActiveRecord::Rollback
					end
				end				

				@rep.assign_attributes(:status => Constants::STATUS_INACTIVE, :deactivated_at => Time.now)
				unless @rep.save
					raise ActiveRecord::Rollback
				end
				success = true
		end
		return success
	end
	
	def valid?
		if @phones.length > 0
			if @phones.length > 1 || @phones[0].phone_type == "personal"
				@errors << "Sales reps are expected to have at most one phone number, of type 'business'"
			end
		end
		
		if @emails.length > 0
			if @emails.select { |email| email.email_type == "personal" }.length > 1
				@errors << "Sales reps may only have one email of type 'personal'"
			end
		
			if @emails.select { |email| email.email_type == "business" }.length > 1
				@errors << "Sales reps may only have one email of type 'business'"
			end
		end
	
		unless @rep.valid?
			@errors += @rep.errors.full_messages
		end		
		
		@drugs.each do |drug|
			unless drug.valid?
				@errors += drug.errors.full_messages
			end
		end		
		
		return (@errors.count == 0)
	end
	
	def save?
		success = false
		
		ActiveRecord::Base.transaction do
			if !@rep.save
				raise ActiveRecord::Rollback
			else
				@emails.each do |email|
					existing_email = @rep.sales_rep_emails.find_by(:email_type => email.email_type)
					if existing_email != nil
						existing_email.assign_attributes(:email_address => email.email_address)
						email = existing_email
					end
					unless email.save
						@errors += email.errors.full_messages
						raise ActiveRecord::Rollback
					end
				end		
				
				if @user_primary_phone.present?
					@rep.user.assign_attributes(:primary_phone => @user_primary_phone)
					unless @rep.user.save
						@errors += @rep.user.errors[:base]
						raise ActiveRecord::Rollback					
					end
				end
		
				@phones.each do |phone|
					existing_phone = @rep.sales_rep_phones.find_by(:phone_type => SalesRepPhone.phone_types[:business])
					if existing_phone != nil
						existing_phone.assign_attributes(:phone_number => phone.phone_number)
						phone = existing_phone
					end
					unless phone.save
						@errors += phone.errors.full_messages
						raise ActiveRecord::Rollback
					end
				end	
				
				drugs_to_delete = DrugsSalesRep.where(:sales_rep_id => @rep.id)
				drugs_to_delete.delete_all
				
				@drugs.each do |drug|
					unless drug.save
						@errors += drug.errors.full_messages
						raise ActiveRecord::Rollback
					end
				end
				success = true
			end
		end
		
		return success
	end  
end