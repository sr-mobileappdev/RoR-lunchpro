class AddToOfficeDeviceLogs < ActiveRecord::Migration[5.1]
  def change
  	add_column :office_device_logs, :office_name, :string
  	add_column :office_device_logs, :device_name, :string
  	add_column :office_device_logs, :device_os, :string
  	add_column :office_device_logs, :device_id, :string
  	add_column :office_device_logs, :connection_type, :integer
  end
end
