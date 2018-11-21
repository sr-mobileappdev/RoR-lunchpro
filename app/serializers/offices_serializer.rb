class OfficesSerializer < ActiveModel::Serializer


  def attributes(attrs, single_office = nil)
    data = super(attrs)
    @sales_rep = scope[:sales_rep] if scope
    @time_range = scope[:time_range] if scope
    @slot_date = scope[:slot_date] if scope

    if scope && scope[:single_office]
      fields = [:id, :name, :address_line1, :address_line2, :address_line3, :creating_sales_rep_id, :city, :state, :postal_code, :country, :total_staff, :office_policy, :food_preferences, :delivery_instructions, :lat, :lon, :policies_last_updated_at, :providers, :diet_restrictions, :appointments, :phone, :timezone, :internal, :appointments_until, :office_exclude_dates]
    elsif scope && scope[:office_slots]
      fields = [:id, :name, :address_line1, :address_line2, :address_line3, :creating_sales_rep_id, :city, :state, :postal_code, :country, :total_staff, :office_policy, :food_preferences, :delivery_instructions, :lat, :lon, :policies_last_updated_at, :slots, :phone, :internal]
    else
      fields = [:id, :name, :address_line1, :address_line2, :address_line3, :creating_sales_rep_id, :city, :state, :postal_code, :country, :total_staff, :office_policy, :food_preferences, :delivery_instructions, :lat, :lon, :policies_last_updated_at, :phone, :internal]
    end
    if scope && !scope[:single_office] && !scope[:office_slots]
      fields = scope.map &:to_sym
    end
    if scope && scope[:offices_sales_reps]
    	fields << :offices_sales_reps
    end
    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end

  def providers
    object.providers.active || []
  end
  
  def office_pocs
  	object.office_pocs.active.where(:primary => true)
  end
  
  def offices_sales_reps
  	if !@sales_rep.present?
		return []
	end  	
  	return object.offices_sales_reps.active.where(:sales_rep_id => @sales_rep.id) || []
  end

  def diet_restrictions
    object.diet_restrictions_offices.joins(:diet_restriction).select("diet_restrictions_offices.*, diet_restrictions.name")
    #DietRestrictionsOffice.joins(:diet_restriction).select("diet_restrictions.name, diet_restrictions_offices.staff_count")
  end

  def appointments
    if @sales_rep
      @time_range = Time.zone.now.to_date.beginning_of_week..Time.zone.now.to_date.end_of_week if !@time_range
      rep = object.sales_reps.where(:id => @sales_rep.id).first
      if rep
        appointments = object.sales_reps.find(@sales_rep.id).appointments.where(:status => 'active', appointment_on: @time_range, :office_id => object.id).order(:appointment_on)
        to_return = []
      	appointments.each do |appt|
      		total_staff_count = (appt.appointment_slot.present? ? appt.appointment_slot.total_staff_count : nil)
      		to_return << appt.as_json(:include => ["appointment_slot"], :methods => ["upcoming_order?"], :except => ["starts_at","ends_at"]).merge(:orders => appt.orders.where(:recommended_by_id => nil, :status => ["active","completed"]).as_json(:include => ["restaurant"]), :starts_at => appt.appointment_time(true), :ends_at => appt.appointment_end_time(true), :total_staff_count => total_staff_count, :diet_restrictions => appt.diet_restrictions_api)
      	end
      	return to_return
      end
    elsif @time_range
    	appointments = object.appointments.where(:status => 'active', appointment_on: @time_range).order(:appointment_on)
        ActiveModelSerializers::SerializableResource.new(appointments, each_serializer: AppointmentsSerializer, scope: {'for_office': true})
    end
   # object.sales_reps.find(@sales_rep.id).appointments.active
  end

  def slots
    manager = Views::OfficeAppointments.new(object, @time_range, @sales_rep, nil, @slot_date)
    manager.upcoming_by_events_api(1)
  end
  
  def office_exclude_dates
  	return object.office_exclude_dates
  end

  def total_staff
    object.total_staff_count || 0
  end

  def office_policy
    object.office_policy || ""
  end

  def food_preferences
    object.food_preferences || ""
  end

  def delivery_instructions
    object.delivery_instructions || ""
  end

  def lat
    object.latitude
  end

  def lon
    object.longitude
  end

end
