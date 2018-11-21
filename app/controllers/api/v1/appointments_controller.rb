class Api::V1::AppointmentsController < ApiController
  include SwaggerBlocks::Appointments
  
  before_action :set_record, only: [:update, :show]
  skip_before_action :check_user_space, only: [:create, :activate_multiple, :index]

  def set_record
    @appointment = Appointment.where.not(status: ['deleted']).find(params[:id])
  end
  
  def show
    drug_names = ApplicationController.helpers.drugs(Drug.find(@appointment.samples_requested))
  	total_staff_count = (@appointment.appointment_slot.present? ? @appointment.appointment_slot.total_staff_count : nil)
  	providers = nil
  	if @appointment.office.present? && @appointment.appointment_slot.present?
  		providers = @appointment.office.providers_available_at(@appointment.appointment_slot)
  	end
  	recommended_order = @appointment.recommended_order
  	recommended_order_json = nil
  	if recommended_order.present? && recommended_order.active?
  		recommended_order_json = recommended_order.as_json(:include => ["restaurant"])
  	end
  	
  	recommended_cuisines = []
  	if @appointment.recommended_cuisines.present?
  		recommended_cuisines = @appointment.cuisines
  	end
  	
  	render json: @appointment.as_json(:include => ["office","appointment_slot"], :methods => ["upcoming_order?","standby_filled?"], :except => ["recommended_cuisines","starts_at","ends_at"]).merge(:recommended_cuisines => recommended_cuisines, :recommended_order => recommended_order_json, :providers => providers, :orders => @appointment.orders.where(:recommended_by_id => nil, :status => ["active","completed"]).as_json(:include => ["restaurant"]), :starts_at => @appointment.appointment_time(true), :ends_at => @appointment.appointment_end_time(true), :total_staff_count => total_staff_count, :diet_restrictions => @appointment.diet_restrictions_api, :drug_names => drug_names)
  end

  def index
    @user = current_user
    @scoped_params = define_scoped_params(params[:include_params])

    # Sending a response of all appointments, unbounded by any criteria is rather pointless except in some extreme cases, so that is currently not supported

    # By default, appointments are returned for the current week only unless a start_date and end_date is sent in
    time_range = Time.zone.now.to_date.beginning_of_week..Time.zone.now.to_date.end_of_week

    if params[:start_date].present? && params[:end_date].present?
      begin
        time_range = Date.parse(params[:start_date])..Date.parse(params[:end_date])
      rescue Exception => ex
      end
    end
    
    if params[:appt_office_id]
    	filtered_appts = []
    	unfiltered_appts = Office.find(params[:appt_office_id]).appointments.where.not(status: ['inactive', 'deleted'])
    	if(params[:days_count].present? && params[:start_date].present?)
    		future_appts = unfiltered_appts.where("appointment_on >= ?", params[:start_date]).order("appointment_on")#.group("to_char(appointment_on,'YYYY-MM-DD')")
    		appt_dates = future_appts.pluck("to_char(appointment_on,'YYYY-MM-DD')").uniq.take(params[:days_count].to_i)
    		appts_to_return = []
    		appt_dates.each do |appt_date|
    			appts_to_return += future_appts.where("appointment_on = ?", appt_date)
    		end
    		render json: appts_to_return and return
    	else
    		time_range.each do |day|
    			kind_of_filtered_appts = unfiltered_appts.where("appointment_on = ?", day)
    			kind_of_filtered_appts.each do |a|
    				filtered_appts << a
    			end
    		end
    		render json: filtered_appts.to_json(:include => parsed_include_params) and return
    	end    	
    end

    @slots = []
    if params[:office_id]
      # Limit to appointments by office

      @office = Office.find(params[:office_id])
      serializable_resource = { office: OfficesSerializer.new(@office) }

      ## Filter by provider ##
      ## TODO - Pass array of provider_ids into this model view OR the upcoming_by_events function
      ## then you will pass that list of provider_ids into the Views::OfficeSlots and the logic inside of this view
      ## should take care of the rest
       manager = Views::OfficeAppointments.new(@office, time_range, nil)
      @slots = manager.upcoming_by_events(1)

    elsif params[:sales_rep_id]
      # Limit to appointments by sales rep
      appts = []
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      if params[:reorder_appt_id].present?
      	past_appt = Appointment.find(params[:reorder_appt_id])
      	appts = @sales_rep.upcoming_appointments_for_reorder(past_appt)
      	if !appts.present?
      		appts = []
      	end
      else
      	appts += @sales_rep.appointments.where(appointment_on: time_range).where(status: ['active', 'completed']).where.not("appointment_on < ? AND (rep_confirmed_at IS NULL OR NOT (food_ordered OR will_supply_food))", Time.now.utc.to_date).order(:appointment_on)
      end
      
      to_return = []
      appts.each do |appt|
        total_staff_count = (appt.appointment_slot.present? ? appt.appointment_slot.total_staff_count : nil)
        to_return << appt.as_json(:include => ["office","appointment_slot"], :methods => ["upcoming_order?"], :except => ["orders", "starts_at","ends_at","recommended_cuisines"]).merge(:orders => appt.orders.where(:recommended_by_id => nil, :status => ["active","completed"]).as_json(:include => ["restaurant"]), :starts_at => appt.appointment_time(true).strftime("%Y-%m-%dT%H:%M:%S.000Z"), :ends_at => appt.appointment_end_time(true).present? ? appt.appointment_end_time(true).strftime("%Y-%m-%dT%H:%M:%S.000Z") : nil, :total_staff_count => total_staff_count, :diet_restrictions => appt.diet_restrictions_api)
      end
      
      render json: to_return and return
    else

      if @user && @user.space_sales_rep?
        serializable_resource = { sales_rep: SalesRepsSerializer.new(@user.sales_rep)}
        manager = Views::SalesRepAppointments.new(@user.sales_rep, time_range, nil)
        @slots = manager.upcoming_by_events(1)
      elsif @user && @user.space_office?
        serializable_resource = { office: OfficesSerializer.new(@user.office)}
        manager = Views::OfficeAppointments.new(@user.office, time_range, nil)
        @slots = manager.upcoming_by_events(1)
      else
        # Sending a response of all appointments, unbounded by any criteria is rather pointless except in some extreme cases, so that is currently not supported
        v1_unaccepted_response("APPT-001-MissingOfficeOrRep", "You must request appointments by office ID or be sales rep ID. A generic list of appointments across the system is not available at this time, via the API.") and return
      end

    end

    response_summary = {count: @slots.count} #response_summary = {count: records.count, total_count: records.total_count, page: @page, total_pages: records.total_pages}
    render json: {meta: response_summary}.merge(serializable_resource).merge({slots: @slots}) and return

  end

  def create    
    if params[:sales_rep_id].present? && params[:office_id] && (params[:slot_date] || params[:slot_ids_and_dates_array]) && (params[:start_time] || params[:appointment_slot_id] || params[:slot_ids_and_dates_array])
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      office = Office.find(params[:office_id])
      date_array = []
      starts_at_array = []
      ends_at_array = []
      slot_id_array = nil

      if params[:slot_date].present?
      	begin
        	date_array << Date.parse(params[:slot_date])
      	rescue Exception => ex
      
      	end     
      end      
      
      if params[:appointment_slot_id].present?
      	slot = AppointmentSlot.find(params[:appointment_slot_id])
      	starts_at_array << slot.starts_at
      	ends_at_array << slot.ends_at
      	slot_id_array = [slot.id]
      elsif params[:start_time].present?
      	begin
      		Time.parse(params[:start_time])
      		starts_at_array << params[:start_time] #force potential exception
      		if params[:end_time].present?
      			Time.parse(params[:end_time]) #force potential exception
      			ends_at_array << params[:end_time]
      		else
      			ends_at_array << nil
      		end
      	rescue
      	
      	end
      elsif params[:slot_ids_and_dates_array].present?
      	slot_id_array = []
      	params[:slot_ids_and_dates_array].each do |slot_id_and_date|
      		slot = AppointmentSlot.find(slot_id_and_date[:slot_id])
      		starts_at_array << slot.starts_at
      		ends_at_array << slot.ends_at
      		date_array << Date.parse(slot_id_and_date[:slot_date])
      		slot_id_array << slot_id_and_date[:slot_id]
      	end
      end
            
      status = Appointment.statuses.key(Constants::STATUS_ACTIVE)
      if params[:slot_ids_and_dates_array].present?      
	      status = Appointment.statuses.key(Constants::STATUS_PENDING)
      end      
         
      created_appts = []
      created_appts_active_records = []
      errors = []
      begin
      	ActiveRecord::Base.transaction do      	
      		starts_at_array.each_with_index do |starts_at, index|
      			date = date_array[index]      			
      			ends_at = ends_at_array[index]      			
      			slot_id = slot_id_array.present? ? slot_id_array[index] : nil
      			appointment = Appointment.new(:sales_rep_id => @sales_rep.id, :office_id => office.id, :created_by_user_id => @sales_rep.user_id, :status => status, :appointment_on => date,
      							:starts_at => starts_at, :ends_at => ends_at, :appointment_slot_id => slot_id)
      			if params[:origin].present?
      				appointment.assign_attributes(:origin => params[:origin])
      			end
      			if params[:title].present? && slot_id.present? && index == 0 && starts_at_array.length == 1 # for non LP appts
      				appointment.assign_attributes(:title => params[:title])
      			end
      			if !appointment.save
      				errors += appointment.errors.full_messages
      				raise ActiveRecord::Rollback
      			else
	      			total_staff_count = (appointment.appointment_slot.present? ? appointment.appointment_slot.total_staff_count : nil)
    	  			diet_restrictions = appointment.diet_restrictions_api
      				created_appts_active_records << appointment
      				created_appts << appointment.as_json(:include => parsed_include_params, :methods => ["upcoming_order?"], :except => ["starts_at","ends_at"]).merge(:starts_at => appointment.appointment_time(true), :ends_at => appointment.appointment_end_time(true), :total_staff_count => total_staff_count, :diet_restrictions => diet_restrictions)
      			end
      		end      	
      	end
      rescue => error
      
      	Rollbar.error(error)
      	raise ActiveRecord::Rollback
      end
      
      if created_appts.length == 0
      	render json: {success: false, message: "An error occurred while trying to make the appointment(s)", errors: errors}, status: 500 and return
      end      
      if status == Appointment.statuses.key(Constants::STATUS_ACTIVE)
      	notifications = []
      	if @sales_rep.user.present?
      		notifications << 202
      	else
      		notifications << 201
      	end
      # notifications
      	created_appts_active_records.each do |created_appt|
      		Managers::NotificationManager.trigger_notifications(notifications, [created_appt, created_appt.office, created_appt.sales_rep, created_appt.appointment_slot])
      		
      	end
      end
      
      # to preserve the previous expected JSON response
      appointment = created_appts.first
	  
      render json: {success: true, message: "Appointment successfully created.", appointement_array: created_appts, appointment: appointment } and return
    else
       v1_unaccepted_response("APPT-003-MissingData", "You must provide the sales rep id, office id, slot date OR array of slot id's and dates, start time OR individual slot id OR array of slot id's and dates, in order to create an appointment") and return
    end

  end

  def update
    if params[:sales_rep_id] && @appointment.sales_rep_id == params[:sales_rep_id].to_i
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      @appointment.assign_attributes(:status => Appointment.statuses.key(Constants::STATUS_ACTIVE))
      unless @appointment.update_attributes(allowed_params)
      	render json: {success: false, message: "An error occurred while updating the appointment", errors: @appointment.errors.full_messages } and return
      end
      #TODO, add logic to check for orders outstanding before allowing a rep to bring food 

    else
      v1_unaccepted_response("APPT-003-MissingData", "You must provide an accurate sales rep id in order to update an appointment") and return
    end
     render json: {success: true, message: "Appointment successfully updated."} and return
  end
  
  def activate_multiple
  	stop_double_bookings = params[:stop_double_bookings].present?
  
  	if !params[:appointment_id_array].present?
  		render json: {success: false, message: "Appointment Id array is required"}, status:500 and return
  	end
  	
  	appts_to_activate = Appointment.where(:id => params[:appointment_id_array])
  	
  	appts_succeeded = []
  	appts_double_booked = []
  	
  	if stop_double_bookings && appts_to_activate.any?
  		sales_rep = appts_to_activate.first.sales_rep
  		appts_double_booked = sales_rep.check_for_duplicate_appointments(appts_to_activate)
  		appts_to_activate = appts_to_activate - appts_double_booked
  	end
  	
  	appts_double_booked_json = []
  	appts_double_booked.each do |db_appt|
  		appts_double_booked_json << db_appt.as_json(:except => ["starts_at","ends_at"]).merge(:starts_at => db_appt.appointment_time(true), :ends_at => db_appt.appointment_end_time(true))
  	end
  	
  	errors = []
  	ActiveRecord::Base.transaction do
  		appts_to_activate.each do |appt|
  			appt.assign_attributes(:status => Appointment.statuses.key(Constants::STATUS_ACTIVE))
  			if !appt.save
  				errors += appt.errors.full_messages
	  			raise ActiveRecord::Rollback  				
  			else
  				appts_succeeded << appt
  			end
  		end
  	end
  	if errors.any?
  		render json: {success:false, errors: errors }, status: 500 and return
  	end  	
  	
  	appts_succeeded.each do |active_appt|
      notifications = []
      if active_appt.sales_rep.user.present?
      	notifications << 202
      else
      	notifications << 201
      end
      # notifications	
      Managers::NotificationManager.trigger_notifications(notifications, [active_appt, active_appt.office, active_appt.sales_rep, active_appt.appointment_slot])
    end
  	
  	render json: {success:true, double_booked_appointments: appts_double_booked_json }, status:200 and return
  end

  def confirm
    if params[:sales_rep_id] && params[:appointment_id]
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      appt = Appointment.find(params[:appointment_id])

      if !@sales_rep.present? || !appt.present? || appt.sales_rep_id != @sales_rep.id
        v1_unaccepted_response("APPT-002-IncorrectData", "You must provide an accurate sales rep id and appointment id in order to confirm an appointment") and return
      end

      if appt.status.in?(['pending', 'inactive'])
        v1_unaccepted_response("APPT-004-IncorrectStatus", "You cannot confirm an appointment that is pending or inactive") and return
      end

      unless appt.confirm_for_rep!
		render json: { success: false, errors: appt.errors.full_messages }, status: 500 and return
	  end
      render json: {success: true, message: "The appointment has been confirmed!"}
    else
       v1_unaccepted_response("APPT-003-MissingData", "You must provide the sales rep id and appointment id in order to confirm an appointment") and return
    end

  end

  def cancel
    if params[:sales_rep_id] && params[:appointment_id]
      @sales_rep = SalesRep.find(params[:sales_rep_id])
      appt = Appointment.find(params[:appointment_id])

      if !@sales_rep.present? || !appt.present? || appt.sales_rep_id != @sales_rep.id
        v1_unaccepted_response("appt-002-incorrectdata", "You must provide an accurate sales rep id and appointment id in order to cancel an appointment") and return
      elsif appt.office.present? && appt.office.internal && (!params[:cancel_reason] || params[:cancel_reason] == "")
        v1_unaccepted_response("appt-002-incorrectdata", "You must provide a cancellation reason when cancelling an appointment") and return
      end

      appt.assign_attributes(cancelled_at: Time.now, status: "inactive", cancelled_by_id: @sales_rep.user_id, cancel_reason: params[:cancel_reason])
		unless appt.save
			render json: { success: false, errors: appt.errors.full_messages }, status: 500 and return
		end
      #TODO: send notiication
      if(appt.orders.count > 0)
        #appt.orders.update_all(:status => 'inactive')
        appt.orders.each do |order_to_cancel|
        	order_to_cancel.update(:status => Constants::STATUS_INACTIVE)
        end
        # Trigger Notification 104 - Office: Cancels appointment WITHOUT attached order
        #Managers::NotificationManager.trigger_notifications([104], [@record], {sales_rep: @record.sales_rep})
      else
        # Trigger Notification 103 - Office: Cancels appointment WITH attached order
        #Managers::NotificationManager.trigger_notifications([103], [@record], {sales_rep: @record.sales_rep})
      end

      render json: {success: true, message: "The appointment has been cancelled!"}    
    else
       v1_unaccepted_response("APPT-003-MissingData", "You must provide the sales rep id and appointment id in order to cancel an appointment") and return
    end

  end

  private
  def allowed_params
    params.permit(:will_supply_food, :bring_food_notes)
  end
end
