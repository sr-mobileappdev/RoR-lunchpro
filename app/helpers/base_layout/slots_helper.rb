module BaseLayout::SlotsHelper

  def office_slot_booked_classes(office_slot = nil)
    return "" unless office_slot && office_slot.kind_of?(Views::Slot)

    if office_slot.state == :reserved && (!office_slot.is_reserved_other_rep?(current_user) || office_slot.is_reserved_by_partner?(current_user)) && office_slot.appointment.status == 'active'
      "lp__slot_booked text-primary"
    elsif office_slot.state == :reserved && !office_slot.is_reserved_other_rep?(current_user) && office_slot.appointment.status == 'pending'
      "lp__slot_available text-info"
    elsif office_slot.state == :reserved && office_slot.is_reserved_other_rep?(current_user)
      "lp__slot_booked"
    elsif office_slot.state == :available
      "lp__slot_available text-success"
    elsif office_slot.state == :reserved 
      "lp__slot_available"
    end

  end

  #cleaning up slots view, return respective font awesome.. in the future may use images
  def office_slot_fa(office_slot = nil)
    return "" unless office_slot && office_slot.kind_of?(Views::Slot)

    if office_slot.state == :reserved && (!office_slot.is_reserved_other_rep?(current_user) || office_slot.is_reserved_by_partner?(current_user)) && 
      office_slot.appointment.status == 'active'
      fa = '<i class="fa fa-responsive fa-user-circle-o text-primary"></i>'
    elsif office_slot.state == :reserved && !office_slot.is_reserved_other_rep?(current_user) && office_slot.appointment.status == 'pending'
      fa ='<i class="fa fa-responsive fa-calendar-plus-o text-info"></i>'
    elsif office_slot.state == :reserved && office_slot.is_reserved_other_rep?(current_user)
      fa = '<i class="fa fa-responsive fa-calendar-times-o"></i>'
    elsif office_slot.state == :available
      fa ='<i class="fa fa-responsive fa-calendar-plus-o text-success"></i>'
    end
    fa.html_safe
  end
end




