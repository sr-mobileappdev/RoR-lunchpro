class CreateOfficeRestaurantExclusions < ActiveRecord::Migration[5.1]
  def change
    create_table :office_restaurant_exclusions do |t|
      t.references :office, foreign_key: true
      t.references :restaurant, foreign_key: true

      t.timestamps
    end
  end
end
