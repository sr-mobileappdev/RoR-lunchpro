class Forms::AdminSalesRepContact < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :contact
  attr_reader :sales_rep

  # This handles either phones or emails depending on the params passed in

  def initialize(sales_rep, user, params = {}, existing_contact = nil)
    @current_user = user
    @sales_rep = sales_rep
    @params = params
    @errors = []

    @contact = existing_contact
  end

  def valid?
    unless @params[:sales_rep_email] || @params[:sales_rep_phone]
      raise "Missing required parameters (:sales_rep_email or :sales_rep_phone)"
    end

    # Validate Sales Rep
    if @params[:sales_rep_email]
      @contact ||= SalesRepEmail.new(status: 'active', sales_rep_id: @sales_rep.id)
      @contact.assign_attributes(@params[:sales_rep_email])
    elsif @params[:sales_rep_phone]
      @contact ||= SalesRepPhone.new(status: 'active', sales_rep_id: @sales_rep.id)
      @contact.assign_attributes(@params[:sales_rep_phone])
    end

    unless @contact.valid?
      @errors += @contact.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def save
    if valid? && persist!
      true
    else
      false
    end
  end

private


  def persist!
    ActiveRecord::Base.transaction do
      if @contact.save
        @contact.update_attributes(created_by_id: @current_user.id)

        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end

end
