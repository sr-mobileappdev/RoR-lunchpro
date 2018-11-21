class RenameCurrencyCentsColumns < ActiveRecord::Migration[5.1]

	def up
		change_column :line_items, :cost, :bigint
		change_column :offices_sales_reps, :per_person_budget, :bigint
		change_column :order_transactions, :authorized_amount, :bigint
		change_column :order_transactions, :captured_amount, :bigint
		change_column :orders, :lunchpro_commission, :bigint
		change_column :restaurants, :min_order_amount, :bigint
		change_column :restaurants, :default_delivery_fee, :bigint
		change_column :sales_reps, :max_tip_amount, :bigint
		change_column :sales_reps, :per_person_budget, :bigint

		change_column_null :users, :is_internal, false, false	# a default without a `null: false` won't enforce the default

		rename_column :line_items, :cost, :cost_cents
		rename_column :offices_sales_reps, :per_person_budget, :per_person_budget_cents
		rename_column :order_transactions, :authorized_amount, :authorized_amount_cents
		rename_column :order_transactions, :captured_amount, :captured_amount_cents
		rename_column :order_transactions, :refunded_amount, :refunded_amount_cents
		rename_column :orders, :lunchpro_commission, :lunchpro_commission_cents
		rename_column :restaurants, :min_order_amount, :min_order_amount_cents
		rename_column :restaurants, :default_delivery_fee, :default_delivery_fee_cents
		rename_column :sales_reps, :max_tip_amount, :max_tip_amount_cents
		rename_column :sales_reps, :per_person_budget, :per_person_budget_cents
	end


	def down
		rename_column :line_items, :cost_cents, :cost
		rename_column :offices_sales_reps, :per_person_budget_cents, :per_person_budget
		rename_column :order_transactions, :authorized_amount_cents, :authorized_amount
		rename_column :order_transactions, :captured_amount_cents, :captured_amount
		rename_column :order_transactions, :refunded_amount_cents, :refunded_amount
		rename_column :orders, :lunchpro_commission_cents, :lunchpro_commission
		rename_column :restaurants, :min_order_amount_cents, :min_order_amount
		rename_column :restaurants, :default_delivery_fee_cents, :default_delivery_fee
		rename_column :sales_reps, :max_tip_amount_cents, :max_tip_amount
		rename_column :sales_reps, :per_person_budget_cents, :per_person_budget
	end

end
