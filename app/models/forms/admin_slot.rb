class Forms::AdminSlot
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :office

  def initialize(user, params = {}, office = nil, existing_slot = nil)
    @current_user = user
    @params = params
    @slot = existing_slot
    @errors = []    
    @office = office
  end

  def valid?
  	unless @office.present?
  		@errors << "Office is missing."
  		return (@errors.count == 0)
  	end

  	unless @params[:days].present? || @params[:day_of_week].present?
  		@errors << "You must select at least one day of the week."
  		return (@errors.count == 0)
  	end

    @params[:slot_type] = @params[:slot_type].downcase
    if @params[:days].present?
    	#loop through days of the weeks selected in selectize and create appt slot for each
    	days = @params[:days].split(",")
    	days.each do |day|
    		slot = AppointmentSlot.new(@params.except(:days))
  		  slot.assign_attributes(:day_of_week => day.to_i)
        @office.appointment_slots << slot
    	end

      unless @office.valid?
        @errors += @office.errors[:base]
      end
    else
      @slot.assign_attributes(@params)
      unless @slot.valid?
        @errors += @slot.errors.full_messages
      end
    end
    return (@errors.count == 0)
  end

  def save
    if persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if valid? && @office.save! && (!@slot || @slot.save)
        return true
      else        
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
