class AddIndexesToUserSubtables < ActiveRecord::Migration[5.1]
	def change
		add_index :user_restaurants, [:user_id, :restaurant_id]
		add_index :user_restaurants, [:restaurant_id, :user_id]

		add_index :user_offices, [:user_id, :office_id]
		add_index :user_offices, [:office_id, :user_id]
	end
end
