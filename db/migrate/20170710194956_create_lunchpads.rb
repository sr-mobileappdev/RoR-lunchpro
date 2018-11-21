class CreateLunchpads < ActiveRecord::Migration[5.1]
  def change
    create_table :lunchpads do |t|
      t.integer :version
      t.string :lunchPad_identifier
      t.string :lunchpad_pin

      t.timestamps
    end
  end
end
