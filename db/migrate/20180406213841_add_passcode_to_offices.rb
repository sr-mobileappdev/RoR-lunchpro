class AddPasscodeToOffices < ActiveRecord::Migration[5.1]
  def change
    add_column :offices, :passcode, :integer
  end
end
