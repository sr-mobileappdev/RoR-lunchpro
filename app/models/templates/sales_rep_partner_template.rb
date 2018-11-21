class Templates::SalesRepPartnerTemplate < Templates::BaseTemplate
  attr_reader :sales_rep_partner

  def initialize(obj = nil)
    @object_type = obj.class
    @sales_rep_partner = obj
  end

  def tags
    return [] if !@sales_rep_partner
    {
      full_name: 'display_name',
      first_name: 'first_name',
      last_name: 'last_name',
      company_name: 'company_name',
    }
  end

end
