class DietRestriction < ApplicationRecord
  include LunchproRecord

  has_and_belongs_to_many :lunch_packs
  has_and_belongs_to_many :menu_items
  has_and_belongs_to_many :providers

  has_many :diet_restrictions_offices
  has_many :offices, through: :diet_restrictions_offices

end
