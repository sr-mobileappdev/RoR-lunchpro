class MenuSubItem < ApplicationRecord
  include LunchproRecord

  belongs_to :menu_item, inverse_of: :menu_sub_items
  has_many :line_items, as: :orderable

  has_many :menu_sub_item_options

  accepts_nested_attributes_for :menu_sub_item_options, reject_if: proc {|attributes| attributes['option_name'].blank?}, allow_destroy: true


    # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
  	unless name.present?
  		menu_item.errors.add(:base, "Menu Option Type is required")
  	end
  	unless qty_allowed.present?
  		menu_item.errors.add(:base, "Quantity Permitted is required")
  	end

  	unless menu_sub_item_options.any?
  		menu_item.errors.add(:base, "You must enter at least one Menu Option")
  	end
  end

  def update_validations
  	create_validations
  end


##### List of virtual attr setters used in CSV Import ######



#### end ####

end
