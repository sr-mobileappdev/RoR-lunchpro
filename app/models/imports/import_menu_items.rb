class Imports::ImportMenuItems
  include CSVImporter

  model MenuItem

  column :restaurant_id, as: ["restaurant"], required: true

  identifier :menu_item_id, :restaurant_id
  when_invalid :skip

end
