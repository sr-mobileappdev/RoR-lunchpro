class RenamePriceToPriceCents < ActiveRecord::Migration[5.1]
  def change
    rename_column :menu_items, :retail_price, :retail_price_cents
    rename_column :menu_items, :wholesale_price, :wholesale_price_cents
    rename_column :lunch_packs, :retail_price, :retail_price_cents
    rename_column :lunch_packs, :wholesale_price, :wholesale_price_cents

    # Orders
    rename_column :orders, :subtotal, :subtotal_cents
    rename_column :orders, :delivery_cost, :delivery_cost_cents
    rename_column :orders, :sales_tax, :sales_tax_cents
    rename_column :orders, :processing_fee, :processing_fee_cents
    rename_column :orders, :tip, :tip_cents
    rename_column :orders, :total, :total_cents

  end
end
