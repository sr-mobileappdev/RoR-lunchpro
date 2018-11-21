class Templates::Web::SalesRepTemplate < Templates::BaseTemplate
  attr_reader :sales_rep

  def initialize(obj = nil)
    @object_type = obj.class
    @sales_rep = obj
  end

  def tags
    return [] if !@sales_rep
    {
      full_name: 'display_name'
    }
  end

end
