class Forms::Api::FormOffice
  attr_reader :errors

  def initialize(office, office_sales_rep = nil)
    @office = office
    @errors = []
    @office_sales_rep = office_sales_rep
  end

  def valid?
    unless @office.valid?
      	@errors += @office.errors.full_messages 
    end
    if @office.new_record?    
	    unless @office_sales_rep.valid?
    		@errors += @office_sales_rep.errors.full_messages
	    end
    end
    return (@errors.count == 0)
  end

  def save
  	success = false
    ActiveRecord::Base.transaction do
    	if @office.new_record?
        	if !(@office.save && save_office_sales_reps)
          		raise ActiveRecord::Rollback
          	else
          		success = true
        	end
        else
        	if !(@office.save)
        		raise ActiveRecord::Rollback
        	else
        		success = true
        	end
        end
    end
    return success
  end

  def save_office_sales_reps
    @office_sales_rep.office_id = @office_id
    if !@office_sales_rep.save
      @errors += @office_sales_rep.errors.full_messages
    	return false
    end
    return true
  end
end