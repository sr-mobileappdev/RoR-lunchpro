class CreateDietRestrictions < ActiveRecord::Migration[5.1]
  def change
    create_table :diet_restrictions do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
