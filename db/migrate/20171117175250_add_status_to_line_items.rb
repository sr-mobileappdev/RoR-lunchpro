class AddStatusToLineItems < ActiveRecord::Migration[5.1]
  def change
    add_column :line_items, :status, :integer, default: 1
  end
end
