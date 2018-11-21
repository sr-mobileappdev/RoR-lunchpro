class LunchPacksMenuItem < ApplicationRecord
  belongs_to :lunch_pack
  belongs_to :menu_item
end
