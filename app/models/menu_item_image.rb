class MenuItemImage < ApplicationRecord
  include LunchproRecord
  mount_uploader :image, Managers::ImageUploaderManager

  belongs_to :menu_item
end
