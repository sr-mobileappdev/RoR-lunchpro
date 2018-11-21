class CreateDietRestrictionsLunchPacks < ActiveRecord::Migration[5.1]
  def change
    create_table :diet_restrictions_lunch_packs do |t|
      t.integer :diet_restriction_id
      t.integer :lunch_pack_id
    end
  end
end
