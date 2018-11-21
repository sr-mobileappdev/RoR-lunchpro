class ConvertTextToVarCharForOffices < ActiveRecord::Migration[5.1]
  def change
  	change_column :offices, :office_policy, :string
  end
end
