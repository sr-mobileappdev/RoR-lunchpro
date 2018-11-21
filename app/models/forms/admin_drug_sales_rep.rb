class Forms::AdminDrugSalesRep < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :sales_rep
  attr_reader :drugs_sales_rep

  def initialize(sales_rep, user, params = {}, existing = nil)
    @current_user = user
    @params = params
    @errors = []

    @sales_rep = sales_rep
    @drugs_sales_rep = existing
  end

  def valid?

    raise "Missing required parameters (:drugs_sales_rep)" unless @params[:drugs_sales_rep]

    # Validate office
    @drugs_sales_rep ||= DrugsSalesRep.new(status: 'active', sales_rep_id: @sales_rep.id)
    @drugs_sales_rep.assign_attributes(@params[:drugs_sales_rep])


    unless @drugs_sales_rep.valid?
      @errors += @drugs_sales_rep.errors.full_messages
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
      if @drugs_sales_rep.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
