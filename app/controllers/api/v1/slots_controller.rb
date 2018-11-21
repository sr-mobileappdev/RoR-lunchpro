class Api::V1::SlotsController < ApiController

skip_before_action :check_user_space, only: [:index]

  def index

    @scoped_params = define_scoped_params(params[:include_params])
    @slots = []
    @sales_rep = nil

    # By default, appointments are returned for the current week only unless a start_date and end_date is sent in
    time_range_start = Time.zone.now.to_date.beginning_of_week
    time_range_end = Time.zone.now.to_date.end_of_week
    slot_date = nil

    if params[:end_date].present?
      begin
      	time_range_end = Date.parse(params[:end_date])
      rescue Exception => ex
      end
    end
    
    if params[:start_date].present?
      begin
      	time_range_start = Date.parse(params[:start_date])
      rescue Exception => ex
      end
    end
    
    time_range = time_range_start..time_range_end
    
    if params[:simple_office_id].present?
    	if(params[:start_date].present? && params[:days_count].present?)
    		slots = Office.find(params[:simple_office_id]).appointment_slots.includes(:appointments).active.to_a
    		slots_to_return = []
    		if(slots.length > 0)
    			iterator = 0
    			max_iterator = params[:days_count].to_i * 7
    			while (slots_to_return.length < params[:days_count].to_i) && (iterator <= max_iterator) do
    				day_of_week = (time_range_start + iterator.days).wday
    				sub_slots = slots.select{ |slot| 
    				AppointmentSlot.day_of_weeks[slot.day_of_week] == day_of_week }
    				if(sub_slots.length > 0)
    					record = {}
    					record[:date] = (time_range_start + iterator.days)
    					record[:appointment_slots] = ActiveModelSerializers::SerializableResource.new(sub_slots, 
    						each_serializer: AppointmentSlotsSerializer, scope: { time_range: record[:date]..record[:date] })
    					slots_to_return << record
    				end
    				iterator = iterator + 1
    			end
    		end
    		
    		render json: { records: slots_to_return } and return
    	else
	    	records = Office.find(params[:simple_office_id]).appointment_slots.active.eager_load(:appointments)
    		render json: { appointment_slots: ActiveModelSerializers::SerializableResource.new(records, each_serializer: AppointmentSlotsSerializer, scope: { time_range: time_range })} and return    	
    	end
    end
    
    if params[:slot_date].present?
      begin
        slot_date = Date.parse(params[:slot_date])
      rescue Exception => ex
      end
    end

    if params[:sales_rep_id]
      @sales_rep = SalesRep.find(params[:sales_rep_id])
    end
    
    if params[:office_id]
      # Limit to appointments by office

      @office = Office.find(params[:office_id])
      
      office_appts_until = @office.appointments_until
      if office_appts_until > time_range_start
      	if office_appts_until < time_range_end
      		time_range_end = office_appts_until
      		time_range = time_range_start..time_range_end
      	end
        manager = Views::OfficeAppointments.new(@office, time_range, @sales_rep, nil, slot_date)
        @slots = manager.upcoming_by_events_api(nil)
        @slots.sort! { |a,b| a[:start] <=> b[:start] }
	  end
    else
      # Sending a response of all appointments, unbounded by any criteria is rather pointless except in some extreme cases, so that is currently not supported
      v1_unaccepted_response("SLOT-001-MissingOffice", "You must request appointment_slots by office ID A generic list of slots across the system is not available at this time, via the API.") and return

    end
    render json: {slots: @slots}
  end

end
