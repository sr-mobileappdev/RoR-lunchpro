class Api::V1::MenuItemsController < ApiController

  before_action :set_record, only: [:show]

  def set_record
    @menu_item = MenuItem.active.find(params[:id])
  end


  def show
  	menu_sub_items = []
  	@menu_item.menu_sub_items.active.each do |sub_item|
  		menu_sub_items << sub_item.as_json(:except => "menu_sub_item_options").merge({ menu_sub_item_options: sub_item.menu_sub_item_options.active })
  	end
	render json: @menu_item.as_json().merge({ menu_sub_items: menu_sub_items, menu_item_images: @menu_item.menu_item_images.active }) and return
  end
end
