class Api::V1::MenusController < ApiController

  def index

    records = []
    filtered_menus = []

	if params[:restaurant_id].present?
		
		restaurant = Restaurant.find(params[:restaurant_id])
		
		if params[:appointment_id].present?
			filtered_menus = restaurant.filtered_menus_by_time(Appointment.find(params[:appointment_id]).starts_at)
		else
			filtered_menus = restaurant.active_menus
		end
	else
		filtered_menus = Menu.active
	end
	
	filtered_menus.each do |m|
		records << m.as_json(:except => "menu_items").merge({ menu_items: m.menu_items.active })
	end

    render json: records and return
  end
  
end
