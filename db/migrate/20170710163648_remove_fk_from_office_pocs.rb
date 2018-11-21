class RemoveFkFromOfficePocs < ActiveRecord::Migration[5.1]
  def change
		remove_foreign_key :office_pocs, :offices
  end
end
