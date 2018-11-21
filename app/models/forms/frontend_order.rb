class Forms::FrontendOrder < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :order

  def initialize(user, params = {}, existing_order = nil, appointment = nil)
    @current_user = user
    @params = params
    @errors = []

    @appointment = appointment
    @order = existing_order.clone

  end

  def valid?
    # Validate office
    #@office ||= Office.new()

    @order.assign_attributes(@params)

    unless @office.valid?
      @errors += @office.errors.full_messages
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

  def reorder
    new_order = nil
    ActiveRecord::Base.transaction do
      new_order = Order.new(@order.attributes.except("id","appointment_id","payment_method_id", "order_number", "created_by_user_id",
       "created_at", "updated_at", "status", "idempotency_key", "recommended_by_id", "updated_by_id"))
      new_order.assign_attributes(:status => 'draft', :appointment_id => @appointment.id)
      if new_order.valid? && new_order.save! && @appointment.update(:restaurant_id => new_order.restaurant_id)
        new_line_items = @order.line_items.clone.to_a
        new_line_items.each do |item|
          if !item.parent_line_item_id
            new_item = LineItem.new(item.attributes.except("order_id", "id", "parent_line_item_id"))
            new_item.order_id = new_order.id
            new_item.save!
            if item.sub_line_items.any?
              item.sub_line_items.each do |sub_item|
                new_sub_item = LineItem.create(sub_item.attributes.except("order_id", "id", "parent_line_item_id"))
                new_sub_item.assign_attributes(:parent_line_item_id => new_item.id, :order_id => new_order.id)
                new_sub_item.save!
              end
            end         
          end          
        end
        new_order.update_total

        @appointment.orders.where.not(id: new_order.id).where(:recommended_by_id => nil).update_all(:status => 'inactive')
        true
      else
        raise ActiveRecord::Rollback
      end
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @order.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
