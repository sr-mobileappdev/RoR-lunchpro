class RemoveWholesalePriceCentsFromMenuItemsAndLunchPacks < ActiveRecord::Migration[5.1]
  def change
  	remove_column :lunch_packs, :wholesale_price_cents
  	remove_column :menu_items,  :wholesale_price_cents
  end
end
