class EditLunchPackBoolOnMenuItems < ActiveRecord::Migration[5.1]
  def change
    change_column :menu_items, :lunchpack, :boolean, :null => false, :default => false
  end
end
