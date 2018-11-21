##purpose of this manager is to handle user merges
class Managers::MergeManager
  attr_reader :errors

  def initialize()
    @errors = []
  end


  #purpose of this method is to merge two reps together by creating a third 'merged' rep
  #info to be merged:
  #appointments
  #orders
  #offices
  #order_reviews
  #sales_rep_phones/emails
  #drugs_sales_reps
  #partners
  #notifications
  #both reps will be set to inactive after the merge

  def merge_reps(source_rep, destination_rep)
  	return false if !source_rep || !destination_rep
  	ActiveRecord::Base.transaction do
	  	begin
	  		#list of attributes that destination rep hasn't set and aren't blacklisted
	  		editable_attrs = destination_rep.attributes.select{|k, v| (!v || v == "") && !blacklisted_rep_attributes.include?(k.to_s)}.map{|k,v| k}
	  		#create new rep record
		  	merged_rep = SalesRep.new(destination_rep.attributes.except(*blacklisted_rep_attributes))
				merged_rep.assign_attributes(source_rep.attributes.select{|k, v| editable_attrs.include?(k) && v && v.present?})
				if destination_rep.is_lp?
					merged_rep.assign_attributes(:user_id => destination_rep.user_id)
				end

		  	unless merged_rep.valid?
		  		@errors << "The rep created from the merge is invalid"
		  		raise ActiveRecord::Rollback
	  			return false	
		  	end


		  	merged_rep.save!
		  	#merge appointments and their orders and order reviews
				appts = source_rep.appointments.to_a + destination_rep.appointments.to_a
		  	appts.each do |appt|
		  		appt.update(:sales_rep_id => merged_rep.id)
		  		appt.orders.each do |order|
		  			order.update(:sales_rep_id => merged_rep.id)
		  			order.order_reviews.select{|rev| rev.reviewer_type == 'SalesRep'}.each do |review|
		  				review.update(:reviewer_id => merged_rep.id)
		  			end
		  		end
		  	end
		  	#merge office sales reps

		  	#grab combination of offices_sales_reps, and array of office_ids
				offices_sales_reps = source_rep.offices_sales_reps.to_a + destination_rep.offices_sales_reps.to_a		  	
				offices_ids = offices_sales_reps.pluck(:office_id)

				#determine if there are duplicate office associations
				dups = offices_ids.group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)

				#if duplicates, keep the destination reps' offices
				if dups.any?
					offices_sales_reps = offices_sales_reps - offices_sales_reps.select{|o| dups.include?(o.office_id) && o.sales_rep_id != destination_rep.id}
				end

				#loop through combined office_sales_reps and change rep id to new merged rep's id
				offices_sales_reps.each do |o|
					o.update(:sales_rep_id => merged_rep.id)
				end

				#loop through existing source_reps/destination_reps offices_sales_reps and set to inactive
				source_rep.offices_sales_reps.update_all(:status => 'inactive')
				destination_rep.offices_sales_reps.update_all(:status => 'inactive')



				#merge sales_rep_emails and sales_rep_phones

				sales_rep_emails = source_rep.sales_rep_emails + destination_rep.sales_rep_emails
				email_types = sales_rep_emails.pluck(:email_type)

				dups = email_types.group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)

				if dups.any?
					sales_rep_emails = sales_rep_emails - sales_rep_emails.select{|email| dups.include?(email.email_type) && email.sales_rep_id != destination_rep.id}
				end

				sales_rep_emails.each do |email|
					email.update(:sales_rep_id => merged_rep.id)
				end

				source_rep.sales_rep_emails.update_all(:status => 'inactive')
				destination_rep.sales_rep_emails.update_all(:status => 'inactive')


				sales_rep_phones = source_rep.sales_rep_phones + destination_rep.sales_rep_phones
				phone_types = sales_rep_phones.pluck(:phone_type)

				dups = phone_types.group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)

				if dups.any?
					sales_rep_phones = sales_rep_phones - sales_rep_phones.select{|phone| dups.include?(phone.phone_type) && phone.sales_rep_id != destination_rep.id}
				end

				sales_rep_phones.each do |phone|
					phone.update(:sales_rep_id => merged_rep.id)
				end

				source_rep.sales_rep_phones.update_all(:status => 'inactive')
				destination_rep.sales_rep_phones.update_all(:status => 'inactive')
				

	
				#update drugs same way as phones/emails
				drugs_sales_reps = source_rep.drugs_sales_reps.active + destination_rep.drugs_sales_reps.active
				drug_ids = drugs_sales_reps.pluck(:drug_id)

				dups = drug_ids.group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)

				if drug_ids.any?
					drugs_sales_reps = drugs_sales_reps - drugs_sales_reps.select{|drug| dups.include?(drug.drug_id) && drug.sales_rep_id != destination_rep.id}
				end

				drugs_sales_reps.each do |drug|
					drug.update(:sales_rep_id => merged_rep.id)
				end

				source_rep.drugs_sales_reps.update_all(:status => 'deleted')
				destination_rep.drugs_sales_reps.update_all(:status => 'deleted')

	
				#destination reps partners have priority, so we keep them and discard source reps. (Source Rep being Non LP, will likely not have any partners.)
				destination_rep.sales_rep_partners.update_all(:sales_rep_id => merged_rep.id)
				partners = SalesRepPartner.where(:partner_id => destination_rep.id)
				partners.update_all(:partner_id => merged_rep.id)
				source_rep.sales_rep_partners.update_all(:status => 'deleted')

				
				source_rep.assign_attributes(:status => 'inactive', :deactivated_at => Time.now)
				destination_rep.assign_attributes(:status => 'inactive', :deactivated_at => Time.now)	
				unless source_rep.save(validate: false) && destination_rep.save(validate: false)					
					@errors << "There was an error merging the reps."
					raise Exception.new('There was an error merging the reps.')					
				end
				
		
				#merge notifications
				#if destination rep is LP, set source rep's notifications to belong to the user of the destination_rep
				#else if destination rep is non lp, set both source/destination rep's notifs to belong to merged rep
				if destination_rep.is_lp?
					Notification.where(:id => source_rep.notifications.pluck(:id)).update_all(:user_id => destination_rep.user_id)
				else
					(destination_rep.notifications + source_rep.notifications).each do |notif|
						related_objects = notif.related_objects						
						if related_objects['non_lp_sales_rep_id'] && related_objects['non_lp_sales_rep_id'].present?
							related_objects['non_lp_sales_rep_id'] = merged_rep.id
						end
						notif.update(:related_objects => related_objects)
					end
				end
	  		return true
	  	rescue Exception => ex
	  		Rollbar.error(ex)
	  		@errors << ex
	  		raise ActiveRecord::Rollback
	  		return false
	  	end
	  end
  end


private

	def blacklisted_rep_attributes
		['status', "user_id", "created_by_id", "created_at", "updated_at", "activated_at", "deactivated_at", "id"]
	end

end
