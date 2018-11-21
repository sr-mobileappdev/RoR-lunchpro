class Forms::AdminSalesRepPartner < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :sales_rep_partner
  attr_reader :sales_rep

  def initialize(sales_rep, user, params = {}, existing_sales_rep_partner = nil)
    @current_user = user
    @sales_rep = sales_rep
    @params = params
    @errors = []

    @sales_rep_partner = existing_sales_rep_partner
  end

  def valid?

    raise "Missing required parameters (:sales_rep_partner)" unless @params[:sales_rep_partner]

    # Validate Sales Rep
    @sales_rep_partner ||= SalesRepPartner.new(status: 'accepted', sales_rep_id: @sales_rep.id)
    @sales_rep_partner.assign_attributes(@params[:sales_rep_partner])

    unless @sales_rep_partner.valid?
      @errors += @sales_rep_partner.errors.full_messages
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
      if @sales_rep_partner.save
        @sales_rep_partner.update_attributes(created_by_id: @current_user.id)

        unless create_inverse_partnership(@sales_rep_partner)
          @errors << "Unable to create related sales rep partnerhip record when saving."
          raise ActiveRecord::Rollback
        end

        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end

  def create_inverse_partnership(sales_rep_partner)
    SalesRepPartner.create!(status: 'accepted', sales_rep_id: sales_rep_partner.partner_id, partner_id: sales_rep_partner.sales_rep_id, created_by_id: sales_rep_partner.created_by_id)
  end
end
