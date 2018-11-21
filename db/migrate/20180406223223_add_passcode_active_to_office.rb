class AddPasscodeActiveToOffice < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :passcode_active, :boolean, null: false, default: false
  end
end
