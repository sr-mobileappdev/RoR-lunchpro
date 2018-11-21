module BaseLayout::CalendarHelper

  def review_appointment_btn_status(office = nil)
    return "" unless office 
    if office.appointments.where(:sales_rep_id => current_user.sales_rep.id, :status => 'pending').count > 0
      ""
    else
      'disabled'
    end
  end
end
