class AddDeactivatedToMenus < ActiveRecord::Migration[5.1]
  def change
    add_column :menus, :deactivated_at, :timestamp
    add_column :menus, :deactivated_by_id, :integer
  end
end
