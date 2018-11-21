class MenuSubItemOption < ApplicationRecord
  include LunchproRecord
  attr_writer :name

  has_many :line_items, as: :orderable

  belongs_to :menu_sub_item, inverse_of: :menu_sub_item_options

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    unless option_name.present?
      menu_item.errors.add(:base, "Menu Option is required")
    end
    unless price_cents.present?
      menu_item.errors.add(:base, "Additional Price is required")
    end
  end

  def update_validations
    create_validations
  end


##### List of virtual attr setters used in CSV Import ######

  def name=(val)
  	write_attribute(:option_name, val)
  end
  def retail_price_cents=(val)
  	write_attribute(:price_cents, val)
  end

#### end ####

end
