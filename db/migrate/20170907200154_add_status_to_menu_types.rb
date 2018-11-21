class AddStatusToMenuTypes < ActiveRecord::Migration[5.1]
  def change
    add_column :menu_types, :status, :integer, default: 1
    add_column :menu_types, :created_by_user_id, :integer
  end
end
