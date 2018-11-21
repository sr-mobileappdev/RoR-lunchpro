class LunchPack < ApplicationRecord
	include LunchproRecord

  belongs_to :restaurant
	has_many :lunch_packs_menu_items
	has_many :menu_items, through: :lunch_packs_menu_items

end
