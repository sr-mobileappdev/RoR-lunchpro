class Forms::OfficesSalesRep < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :offices_sales_rep
  attr_reader :sales_rep
  attr_reader :office

  def initialize(user, office = nil, sales_rep = nil, params = {}, existing_offices_sales_rep = nil)
    @current_user = user
    @sales_rep = sales_rep
    @office = office
    @errors = []
    @params = params
    @offices_sales_rep = existing_offices_sales_rep
  end

  def add_office
    @errors << "You must be logged in as a sales rep to add an office" unless @office && @sales_rep
    @errors << "A user is required when saving a sales rep to an office" unless @current_user

    base_params = {status: 'active', office_id: @office.id, sales_rep_id: @sales_rep.id, :created_by_id => @current_user.id}
    @offices_sales_rep = ::OfficesSalesRep.find_or_create_by(base_params)

    unless @offices_sales_rep.valid?
      @errors += @offices_sales_rep.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def valid?
    raise "Missing required parameters (:office)" unless @params[:office]

    office = @params[:office]
    @errors << "You must be logged in as a sales rep to add an office" unless @sales_rep
    @errors << "A user is required when saving a sales rep to an office" unless @current_user

    #@office_phone = office[:poc_phone]
    @office ||= Office.new()

    if @office.new_record?
      @office.assign_attributes(:created_by_id => office[:created_by_id], :internal => office[:internal], :timezone => office[:timezone], :activated_at => Time.now, 
        :phone => office[:phone], :activated_by_id => @current_user.id, :creating_sales_rep_id => @params[:creating_sales_rep_id], 
        :name => office[:name], :address_line1 => office[:address_line1], :address_line2 => office[:address_line2], 
        :city => office[:city], :state => office[:state], :postal_code => office[:postal_code], :total_staff_count => office[:total_staff_count])
    else
       @office.assign_attributes(:timezone => office[:timezone], :name => office[:name], :phone => office[:phone], 
        :address_line1 => office[:address_line1], :address_line2 => office[:address_line2], 
        :city => office[:city], :state => office[:state], :postal_code => office[:postal_code], :total_staff_count => office[:total_staff_count])
    end


    unless @office.valid?
      @errors += @office.errors.full_messages 
    end
    return (@errors.count == 0)
  end

  def check_referral
    if @params[:referral_id].present?
      if OfficeReferral.find(@params[:referral_id].to_i).update(:office_id => @office.id)

      else
        false
      end
    end
    true
  end

  def remove_office
    ActiveRecord::Base.transaction do
      begin
        @offices_sales_rep.update_attributes(:status => "inactive")
        appointments = @sales_rep.appointments.select{|appt| appt.office_id == @office.id && appt.appointment_time(true) > Time.now.in_time_zone(@office.timezone)}
        appointments.each do |appt|
          appt.update(:cancelled_at => Time.now, :cancelled_by_id => @current_user.id, :status => 'inactive')
          appt.orders.each do |order|
            order.update(:status => 'inactive')
          end
        end        
      rescue => ex
        Rollbard.error(ex)
        raise ActiveRecord::Rollback
        return false
      end
    end
  end

  def save
    ActiveRecord::Base.transaction do
      if @office.new_record?
        if @office.save && create_offices_sales_rep && check_referral
          return true
        else
          raise ActiveRecord::Rollback
          return false
        end
      elsif !@office.new_record? && @office.save
        return true 
      else              
        raise ActiveRecord::Rollback
        return false
      end
    end
  end

  def update_poc
    @office_poc = @office.office_poc
    @office_poc.assign_attributes(:phone => @office_phone)

    ActiveRecord::Base.transaction do
      if @office_poc.save
      else
 #       @errors << "There was an error processing the request. Please try again" 
      end
    end
    return (@errors.count == 0)
  end

  def create_poc
    @office_poc = OfficePoc.new(:primary => true, :first_name => "Office", :last_name => "contact", :phone => @office_phone, :office_id => @office.id)
    unless @office_poc.valid?
      @errors += @office_poc.errors.full_messages
      return (@errors.count == 0)
    end    

    ActiveRecord::Base.transaction do
      if @office_poc.save
      else
 #       @errors << "There was an error processing the request. Please try again" 
      end
    end
    return (@errors.count == 0)
  end

  def create_offices_sales_rep
    ActiveRecord::Base.transaction do
      if @office.offices_sales_reps.create(:sales_rep_id => @params[:creating_sales_rep_id], :status => 'active', :created_by_id => @current_user.id)
        true
      else
        @errors << "There was an error processing the request. Please try again" 
      end
    end
    return (@errors.count == 0)
  end

  #used to update multiple office_sales_rep.budgets at once
  def update_budgets
    @errors << "You must be logged in as a sales rep to add an office" unless @sales_rep
    @errors << "Invalid form data." unless @params[:sales_rep].present?
    ActiveRecord::Base.transaction do
      if @sales_rep.update(@params[:sales_rep])
      else
        @errors << "There was an error processing the request. Please try again" 
      end
    end
    return (@errors.count == 0)
  end
end
