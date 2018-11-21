class ChangeOfficeDevicesToOfficeDeviceLogs < ActiveRecord::Migration[5.1]
  def change
  	rename_table :office_devices, :office_device_logs
  end
end
