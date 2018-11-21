class ChangePasscodeToCharVarForOffices < ActiveRecord::Migration[5.1]
  def change
    change_column :offices, :passcode, :string
  end
end
