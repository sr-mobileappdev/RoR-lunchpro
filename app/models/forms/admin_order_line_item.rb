class Forms::AdminOrderLineItem < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :order
  attr_reader :user

  def initialize(user, order, params = {})
    @current_user = user
    @params = params
    @errors = []

    @order = order
    @line_item = (params[:line_item_id].present?) ? LineItem.find(params[:line_item_id]) : LineItem.new(order_id: @order.id)

    raise "Missing required parameters (:line_item)" unless @params[:line_item]

    # Validate Line Item
    menu_item = MenuItem.find(@params[:line_item][:orderable_id])

    @line_item.assign_attributes(@params[:line_item])
    @line_item.unit_cost_cents = menu_item.retail_price_cents
    @line_item.cost_cents = menu_item.retail_price_cents * @line_item.quantity
    @line_item.people_served = menu_item.people_served
    @line_item.category = menu_item.category

  end

  def valid?

    unless @line_item.valid?
      @errors += @line_item.errors.full_messages
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
      if @line_item.save
        @order.update_total
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
