class AppointmentsSerializer < ActiveModel::Serializer

  def attributes(attrs, unknown_param = nil)
    data = super(attrs)
  
    if scope && scope[:for_office]
      fields = [:id, :start, :end, :appointment_timezone, :status, :rep_notes, :bring_food_notes, :will_supply_food, :office_notes, :rep_confirmed, :office_confirmed, :restaurant_confirmed, :food_ordered, :delivery_notes, :appointment_slot_id, :appointment_slot, :orders]
    else
      fields = [:id, :appointment_on, :appointment_time, :appointment_timezone, :sales_rep, :office, :rep_notes, :office_notes, :confirmations, :food_ordered, :delivery_notes, :orders]
    end
    if scope && !scope[:for_office]
      fields = scope.map &:to_sym
    end

    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end
  def appointment_slot
    if(object.appointment_slot.present?)
	  return {name: object.appointment_slot.name}
	else
	  return nil
	end
  end
  
  def orders
  	object.orders.includes(:restaurant).as_json(:include => :restaurant)
  end

  def start
    object.appointment_time(true)
  end

  def end
    object.appointment_end_time(true)
  end

  def sales_rep
    if object.sales_rep
      SalesRepsSerializer.new(object.sales_rep).serializable_hash
    else
      nil
    end
  end

  def office
    if object.office
      OfficesSerializer.new(object.office).serializable_hash
    else
      nil
    end
  end

  def confirmations
    conf = {}
    conf[:sales_rep] = (object.rep_confirmed) ? true : false
    conf[:office] = (object.office_confirmed) ? true : false
    conf[:restaurant] = (object.restaurant_confirmed) ? true : false

    conf
  end

  def delivery_notes
    object.delivery_notes.present? ? object.delivery_notes : ""
  end

  def appointment_time
    object.appointment_time(true)
  end

  def appointment_timezone
    object.time_zone
  end

end
