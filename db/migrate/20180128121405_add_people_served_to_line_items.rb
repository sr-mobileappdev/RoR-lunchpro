class AddPeopleServedToLineItems < ActiveRecord::Migration[5.1]
  def change
    add_column :line_items, :people_served, :integer
    add_column :line_items, :category, :integer
  end
end
