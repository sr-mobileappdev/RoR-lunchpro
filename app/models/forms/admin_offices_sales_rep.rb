class Forms::AdminOfficesSalesRep < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :offices_sales_rep
  attr_reader :sales_rep
  attr_reader :office

  def initialize(sales_rep_or_office, user, params = {}, existing_offices_sales_rep = nil)
    @current_user = user
    @sales_rep = (sales_rep_or_office && sales_rep_or_office.kind_of?(SalesRep)) ? sales_rep_or_office : nil
    @office = (sales_rep_or_office && sales_rep_or_office.kind_of?(Office)) ? sales_rep_or_office : nil
    @params = params
    @errors = []

    @offices_sales_rep = existing_offices_sales_rep
  end

  def valid?

    raise "Missing required parameters (:offices_sales_rep)" unless @params[:offices_sales_rep]

    # Validate Sales Rep
    base_params = {status: 'active', office_id: @office.id} if @office
    base_params = {status: 'active', sales_rep_id: @sales_rep.id} if @sales_rep

    @offices_sales_rep ||= OfficesSalesRep.new(base_params)
    @offices_sales_rep.assign_attributes(@params[:offices_sales_rep])

    unless @offices_sales_rep.valid?
      @errors += @offices_sales_rep.errors.full_messages
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
      if @offices_sales_rep.save
        @offices_sales_rep.update_attributes(created_by_id: @current_user.id)
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
