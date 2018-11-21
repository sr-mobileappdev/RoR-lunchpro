class AddModifiedByUserIdToLunchPacks < ActiveRecord::Migration[5.1]
  def change
    add_column :lunch_packs, :modified_by_user_id, :integer
  end
end
