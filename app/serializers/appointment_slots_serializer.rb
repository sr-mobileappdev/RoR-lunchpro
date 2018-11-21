class AppointmentSlotsSerializer < ActiveModel::Serializer


  def attributes(attrs, arg_2 = nil)
    data = super(attrs)
    @time_range = scope[:time_range] if scope
    
    fields = [:id, :name, :day_of_week, :starts_at, :ends_at, :staff_count, :office_id, :status, :slot_type, :appointments]

    fields.each do |attr|
      data[attr] = self.respond_to?(attr) ? self.try(attr) : object.try(attr)
    end
    data
  end

  def appointments
    if [:simple_office_id].present? == true
      @appmnts = object.appointments.select{ |x| x.status == 'active' && @time_range.cover?(x.appointment_on) }.sort_by{ |x| x.appointment_on }
      to_return = []
      @appmnts.each do |ap|
      	if ap.food_ordered != nil && ap.food_ordered == true
          #
        else
          ap.restaurant_id = nil
        end
        to_return << ap.slice(:id, :sales_rep_id, :bring_food_notes, :appointment_on, :will_supply_food, :starts_at, :ends_at, :rep_confirmed_at, :restaurant_id).merge({ :restaurant_name => (ap.restaurant_id.present? && ap.restaurant.present? ? ap.restaurant.name : nil), :sales_rep_first_name => ap.sales_rep.first_name, :sales_rep_last_name => ap.sales_rep.last_name, :sales_rep_company_name => ap.sales_rep.company.present? ? ap.sales_rep.company.name : nil, :sales_rep_non_lp => ap.sales_rep.non_lp, :sales_rep_profile_image => ap.sales_rep.profile_image.present? ? ap.sales_rep.profile_image.url : nil })
      end
      to_return
    else
      object.appointments.where(:status => 'active', appointment_on: @time_range).order(:appointment_on)
    end
  end
end
