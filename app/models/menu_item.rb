class MenuItem < ApplicationRecord
	include LunchproRecord

	belongs_to :modified_by_user, class_name: 'User'
  belongs_to :restaurant

  has_many :menu_item_images

  has_many :line_items, as: :orderable

	has_many :lunch_packs_menu_items
	has_many :lunch_packs, through: :lunch_packs_menu_items

  has_many :menu_sub_items, dependent: :destroy

	has_and_belongs_to_many :diet_restrictions
  has_and_belongs_to_many :menus, dependent: :destroy

	accepts_nested_attributes_for :menu_sub_items, allow_destroy: true
  enum category: { cat_appetizer: 10, cat_small_plate: 20, cat_entree: 30, cat_dessert: 40, cat_beverage: 50, cat_buffet_style: 60, cat_platter: 70, cat_side: 80, cat_salad: 90, cat_miscellaneous: 100 }


  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update


  def self.draft
    inactive.where(published_at: nil)
  end

  def create_validations
    unless name.present?
      self.errors.add(:base, "Item name is required")
    end
    unless retail_price_cents > 0
      self.errors.add(:base, "Retail Price is required")
    end

  end

  def lunchpack(for_grouping = false)
    if for_grouping
      if lunchpack
        "Lunchpacks"
      end
    else
      read_attribute(:lunchpack)
    end
  end

  def update_validations
    unless name.present?
      self.errors.add(:base, "Item name is required")
    end
    unless retail_price_cents > 0
      self.errors.add(:base, "Retail Price is required")
    end
  end

  def has_options?
    self.menu_sub_items.joins(:menu_sub_item_options).includes(:menu_sub_item_options).
              where("menu_sub_item_options.status = 1 and menu_sub_items.status = 1").count > 0
  end

  # Method necessary for tables
  def is_inactive
    self.inactive?
  end

  def is_lunchpack?
    lunchpack
  end

  def activate!
    self.unpublished_at = nil
    self.published_at = Time.now
    self.status = "active"

    self.save
  end

  def deactivate!
    self.published_at = nil
    self.unpublished_at = Time.now
    self.status = "inactive"

    self.save
  end

  def available_in_menus
    menus.active
  end

  def menu_item
    self
  end

  def self.__columns
    cols = {available_in_menus: 'Available In Menus', menu_item: 'Item'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
