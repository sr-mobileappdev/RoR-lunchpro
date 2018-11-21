class CreateDietRestrictionsOffices < ActiveRecord::Migration[5.1]
  def change
    create_table :diet_restrictions_offices do |t|
      t.references :office
      t.references :diet_restriction
      t.integer :staff_count

      t.timestamps
    end
  end
end
