class Admin::ImportsController < AdminController

  def new
    if @xhr
      if params[:import_model].present? && params[:import_model] == "MenuItem"
        @restaurant = Restaurant.find(params[:restaurant_id]) if params[:restaurant_id].present?
        render json: { html: (render_to_string :partial => 'new_menu_items', :layout => false, :formats => [:html]) }
        return
      else
        head :ok
      end
    else
      head :ok
    end
  end

  def update
  end

  def create
    man = Managers::CsvManager.new
    unless params[:file].present? && params[:restaurant_id].present? && Restaurant.where(:id => params[:restaurant_id]).first
      redirect_to request.referrer and return
    end
    if man.import_menu_items(current_user, params[:restaurant_id], params[:file])
      flash[:success] = "Menu import successful!"
    else
      flash[:error] = "There was an error importing the menu."
    end
    redirect_to request.referrer and return
  end

end
