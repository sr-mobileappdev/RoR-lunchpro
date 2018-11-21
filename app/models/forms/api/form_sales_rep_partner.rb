class Forms::Api::FormSalesRepPartner
  attr_reader :errors
  
  def initialize(partner)
  	@partner = partner
  	@errors = []
  end
  
  def valid?
  	unless @partner.valid?
  		@errors += @partner.errors.full_messages
  	end
  	  	
  	return (@errors.length == 0)
  end
  
  def save?
  		success = false
		ActiveRecord::Base.transaction do
			complementary_rejected_partner = nil
			if @partner.rejected?
				complementary_rejected_partner = SalesRepPartner.find_by(:sales_rep_id => @partner.partner_id, :partner_id => @partner.sales_rep_id, :status => Constants::STATUS_REJECTED)		
			end
			if complementary_rejected_partner != nil
				complementary_rejected_partner.status = Constants::STATUS_DELETED
				@partner.status = Constants::STATUS_DELETED
				
				if !(@partner.save && complementary_rejected_partner.save)
					raise ActiveRecord::Rollback
				else
					success = true
				end
			else
				if !@partner.save
					raise ActiveRecord::Rollback
				else
					success = true
				end				
			end
		end		
		return success
  end
  
  	def soft_delete?
		@partner.status = Constants::STATUS_DELETED
		return @partner.save
	end
end