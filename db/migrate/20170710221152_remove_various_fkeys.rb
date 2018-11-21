class RemoveVariousFkeys < ActiveRecord::Migration[5.1]
	def change
		remove_foreign_key :office_restaurant_exclusions, :offices
		remove_foreign_key :office_restaurant_exclusions, :restaurants
		remove_foreign_key :order_transactions, :orders
		remove_foreign_key :order_transactions, :payments
	end
end
