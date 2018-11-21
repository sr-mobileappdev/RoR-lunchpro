class AddCreatedByIdToLineItems < ActiveRecord::Migration[5.1]
  def change
    add_column :line_items, :created_by_id, :integer
  end
end
