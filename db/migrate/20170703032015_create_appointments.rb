class CreateAppointments < ActiveRecord::Migration[5.1]
  def change
    create_table :appointments do |t|
      t.references :sales_rep
      t.references :office
      t.references :appointment_slot
      t.text :rep_notes
      t.text :office_notes
      t.boolean :office_confirmed
      t.boolean :rep_confirmed
      t.boolean :restaurant_confirmed
      t.references :created_by_user
      t.boolean :sample_requested
      t.boolean :sample_sent
      t.boolean :food_ordered
      t.boolean :food_sent
      t.boolean :funds_funded
      t.text :delivery_notes
      t.integer :status
      t.text :bring_food_notes

      t.timestamps
    end
  end
end
