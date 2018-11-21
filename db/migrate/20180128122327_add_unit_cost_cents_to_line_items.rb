class AddUnitCostCentsToLineItems < ActiveRecord::Migration[5.1]
  def change
    add_column :line_items, :unit_cost_cents, :integer
  end
end
