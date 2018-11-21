class Admin::ImpersonationController < AdminController
	before_action :set_record
  	def set_record
    	@record = User.find(params[:user_id])
	end

	def impersonate
		impersonator_id = current_user.id
		if sign_in(:user, @record)
		  session[:impersonator_id] = impersonator_id
		  session[:impersonator_return_url] = request.referrer

		  case @record.entity.class.name
		  when "SalesRep"
		    redirect_to current_rep_calendars_path
		  when "Office"
		    redirect_to current_office_calendars_path
		  when "Restaurant"
		  	redirect_to select_restaurant_restaurant_account_index_path
		  end
		end
	end


	def order
		return if !params[:appointment_id].present?
		appt = Appointment.find(params[:appointment_id])
		return if !appt.active?

		impersonator_id = current_user.id
		if sign_in(:user, @record)
		  session[:impersonator_id] = impersonator_id
		  session[:impersonator_return_url] = request.referrer

		  case @record.entity.class.name
		  when "SalesRep"
		    if appt.active_order
				redirect_to select_food_rep_appointment_path(appt)
		    else
				redirect_to select_restaurant_rep_appointment_path(appt)
		    end
		  when "Office"
	    	if appt.active_order
				redirect_to select_food_office_appointment_path(appt)
		    else
				redirect_to select_restaurant_office_appointment_path(appt)
		    end
		  end
		end
	end

end
