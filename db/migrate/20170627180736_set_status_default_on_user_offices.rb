class SetStatusDefaultOnUserOffices < ActiveRecord::Migration[5.1]
  def change
    change_column :user_offices, :status, :integer, default: 1
  end
end


