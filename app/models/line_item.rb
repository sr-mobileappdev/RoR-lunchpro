class LineItem < ApplicationRecord
  include LunchproRecord

	belongs_to :order
  belongs_to :orderable, polymorphic: true
  belongs_to :created_by, class_name: 'User'

  belongs_to :parent_line_item, class_name: 'LineItem'
  has_many :sub_line_items, class_name: 'LineItem', foreign_key: 'parent_line_item_id'

  enum category: { cat_appetizer: 10, cat_small_plate: 20, cat_entree: 30, cat_dessert: 40, cat_beverage: 50, cat_buffet_style: 60, cat_platter: 70, cat_side: 80, cat_salad: 90, cat_miscellaneous: 100 }

	validates_presence_of :order

  # -- Validates
  before_save :set_quantity

  def set_quantity
    if !self.quantity || self.quantity == 0
      self.quantity = 1
    end
  end

  def option_lines
    options = []
    # Returns new empty lines OR existing lines that align with the sub options available on this line item
    if orderable && orderable_type == "MenuItem"
      orderable.menu_sub_items.active.each do |sub_item|
        options << {id: sub_item.id, name: sub_item.name, qty_allowed: sub_item.qty_allowed, options: sub_item.menu_sub_item_options.order("option_name ASC") }
      end
    else
      # Options under anything except a Menu Item are not allowed
      return []
    end

    options
  end

  def has_option?(option)
    # determine if this line item has a related, selected sub-item
    sub_line_items.where(orderable_id: option.id).count > 0
  end

  def orderable_name
    if orderable && orderable.kind_of?(MenuSubItemOption)
      name || "#{orderable.menu_sub_item.name}: #{orderable.option_name}"
    else
      name || ((orderable && orderable.respond_to?("name")) ? orderable.name : "")
    end
  end

  def cost_with_sub_items
    self.cost_cents + ((self.sub_line_items.select{|li| li.active? || li.draft?}.pluck(:unit_cost_cents).sum || 0) * (self.quantity || 0))
  end

	def serializable_hash(options)
  		if !options.present?
  			options = Hash.new()
  		end
  		
		if options[:except].present?
			options[:except] << "name"
		else
			options[:except] = ["name"]
		end
		json_to_return = super
		json_to_return = json_to_return.merge({ name: orderable_name })
		return json_to_return
  end

end
