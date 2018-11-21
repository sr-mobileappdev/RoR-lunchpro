class AddLunchPackBoolToMenuItems < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_items, :lunchpack, :bool
  end
end
