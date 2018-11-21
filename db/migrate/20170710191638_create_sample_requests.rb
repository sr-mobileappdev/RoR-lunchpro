class CreateSampleRequests < ActiveRecord::Migration[5.1]
  def change
    create_table :sample_requests do |t|
      t.references :appointment
      t.references :drug
      t.text :note
      t.boolean :fulfilled

      t.timestamps
    end
  end
end
