class CreateOfficeDevices < ActiveRecord::Migration[5.1]
  def change
    create_table :office_devices do |t|
      t.integer :office_id
      t.timestamp :timestamp
      t.string :app_version

      t.timestamps
    end
  end
end
