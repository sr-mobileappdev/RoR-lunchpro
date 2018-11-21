module IconsHelper
  def appt_icon(appointment = nil)
    response = nil
    if appointment.appointment_slot && appointment.upcoming?
      if (appointment.appointment_slot.name == "Sample") && appointment.rep_confirmed
        response = '<svg viewbox="0 0 80 80" width="70" height="70"><use xlink:href="#check-circle-o"/></svg>'
      elsif (appointment.food_ordered? || appointment.will_supply_food) && appointment.rep_confirmed
        response = '<svg viewbox="0 0 80 80" width="70" height="70"><use xlink:href="#check-circle-o"/></svg>'
      elsif !appointment.sales_rep_confirmable? && !appointment.rep_confirmed
        response = '<svg viewbox="0 0 52 52" width="70" height="70"><use xlink:href="#calendar-clock"/></svg>'
      elsif (appointment.sales_rep_confirmable? && !appointment.rep_confirmed) || (!appointment.food_ordered? && !appointment.will_supply_food)
        response = '<svg viewbox="0 0 45 45" width="70" height="70"><use xlink:href="#calendar-exclamation"/></svg>'
      end
    elsif !appointment.appointment_slot
      if appointment.upcoming_order?
        response = '<svg viewbox="0 0 52 52" width="70" height="70"><use xlink:href="#calendar-clock"/></svg>'
      else
        response = '<svg viewbox="0 0 45 45" width="70" height="70"><use xlink:href="#hourglass-circle-o"/></svg>'
      end
    else
      response = '<svg viewbox="0 0 45 45" width="70" height="70"><use xlink:href="#hourglass-circle-o"/></svg>'
    end
    response.html_safe if response
  end

  def slot_icon(slot = nil)
    response = nil
    if slot.is_booked? && slot.is_reserved_other_rep?(current_user) && !slot.is_reserved_by_partner?(current_user)
      response = '<svg viewbox="0 0 52 52" width="70" height="70"><use xlink:href="#calendar-clock"/></svg>'
    elsif slot.is_booked? && (!slot.is_reserved_other_rep?(current_user) || slot.is_reserved_by_partner?(current_user)) && slot.appointment.status == 'active'

      if slot.booked_by_rep && slot.booked_by_rep.profile_image && slot.booked_by_rep.profile_image.url
        response = '<div class="profile-image-container"><img class="profile-picture" src="' + slot.booked_by_rep.profile_image.url + '", alt="Rep Profile Image"/></div>'
      else
        response = '<div class="profile-image-container"><img class="profile-picture" alt="Missing Image" src="' + asset_path('missing_image.png') + '"/></div>'
      end
    else slot.is_booked? && !slot.is_reserved_other_rep?(current_user) && slot.appointment.status == 'pending'
      response = '<svg viewbox="0 0 50 50" width="70" height="70"><use xlink:href="#calendar-plus"/></svg>'
    end
    response.html_safe if response
  end

  def slot_food_icon(slot_type = nil, height = 60, width = 60)
    response = nil
    case slot_type
    when "sample"
      response = rx_circle_icon(height, width)
    when "breakfast"
      response = egg_circle_icon(height, width)
    when "lunch"
      response = om_food_icon(height, width)
    when "dinner"
      response = fork_knife_circle_icon(height, width)
    when "snack"
      response = apple_circle_icon(height, width)
    else

    end
    response
  end

  def list_type_icon(list_type = nil)
    response = nil
    case list_type
    when "none"
    when "blacklist"
      response = ban_icon
    when "standby"
      response = flag_icon
    end

  end

  def gear_icon
    '<svg viewbox="0 0 26 26" width="25" height="25"><use xlink:href="#gear-o"/></svg>'.html_safe
  end

  def egg_circle_icon(height = 60, width = 60)
    r = '<svg viewbox="0 0 50 50" width="'+width.to_s+'" height="'+height.to_s+'"><use xlink:href="#egg-circle"/></svg>'
    r.html_safe
  end

  def rx_circle_icon(height = 60, width = 60)
    r = '<svg viewbox="0 0 50 50" width="'+width.to_s+'" height="'+height.to_s+'"><use xlink:href="#rx-circle"/></svg>'
    r.html_safe
  end
  def fork_knife_circle_icon(height = 60, width = 60)
    r = '<svg viewbox="0 0 50 50" width="'+width.to_s+'" height="'+height.to_s+'"><use xlink:href="#fork-knife-circle"/></svg>'
    r.html_safe
  end

  def fork_knife_icon
    '<svg viewbox="0 0 50 50" width="60" height="60"><use xlink:href="#fork-knife-circle-o"/></svg>'.html_safe
  end


  def ban_icon
    '<svg viewbox="0 0 20 20" width="20" height="20"><use xlink:href="#ban"/></svg>'.html_safe
  end

  def flag_icon
    '<svg viewbox="0 0 20 20" width="20" height="20"><use xlink:href="#flag"/></svg>'.html_safe
  end

  def apple_circle_icon(height = 60, width = 60)
    r = '<svg viewbox="0 0 50 50" width="'+width.to_s+'" height="'+height.to_s+'"><use xlink:href="#apple-circle"/></svg>'
    r.html_safe
  end

  def om_food_icon(height = 60, width = 60)
    r = '<svg viewbox="0 0 50 50" width="'+width.to_s+'" height="'+height.to_s+'"><use xlink:href="#bowl-food"/></svg>'
    r.html_safe
  end

  def om_user_past_icon
    '<svg viewbox="0 0 50 50" width="60" height="60"><use xlink:href="#agent-circle-past"/></svg>'.html_safe
  end
  def om_food_past_icon
    '<svg viewbox="0 0 50 50" width="60" height="60"><use xlink:href="#bowl-food-past"/></svg>'.html_safe
  end

  def om_food_past_icon_xl
    '<svg viewbox="0 0 50 50" width="80" height="80"><use xlink:href="#bowl-food-past"/></svg>'.html_safe
  end

  def om_user_icon
    '<svg viewbox="0 0 50 50" width="60" height="60"><use xlink:href="#agent-circle"/></svg>'.html_safe
  end

  def notes_icon
    '<svg viewbox="3 0 25 25" width="25" height="25"><use xlink:href="#notebook-pencil"/></svg>'.html_safe
  end

  def dinner_tray_icon
    '<svg viewbox="0 0 30 30" width="30" height="30"><use xlink:href="#dinner-tray"/></svg>'.html_safe
  end

  def orders_dinner_tray_icon
    '<svg viewbox="0 0 30 30" width="60" height="60"><use xlink:href="#dinner-tray"/></svg>'.html_safe
  end

  def order_history_hourglass_icon(width = 70, height = 70)
    r = '<svg viewbox="0 0 45 45"  width="'+width.to_s+'" height="'+height.to_s+'"><use xlink:href="#hourglass-circle-o"/></svg>'
    r.html_safe
  end

  def order_history_hourglass_icon_pdf(width = 70, height = 70)
    r = '<svg viewbox="0 -2 48 47"  width="'+width.to_s+'" height="'+height.to_s+'"><use xlink:href="#hourglass-circle-o"/></svg>'
    r.html_safe
  end
  def review_calendar_icon
    '<svg viewbox="0 0 50 50" width="100" height="100"><use xlink:href="#calendar-plus"/></svg>'.html_safe
  end
  def calendar_plus_icon
    '<svg viewbox="0 0 50 50" width="70" height="70"><use xlink:href="#calendar-plus"/></svg>'.html_safe
  end
  def calendar_plus_icon_xl
    '<svg viewbox="0 0 50 50" width="85" height="85"><use xlink:href="#calendar-plus"/></svg>'.html_safe
  end
  def finish_calendar_icon
    '<svg viewbox="0 0 80 80" width="70" height="70"><use xlink:href="#check-circle-o"/></svg>'.html_safe
  end

  def check_icon_xl
    '<svg viewbox="0 0 80 80" width="120" height="120"><use xlink:href="#check-circle-o"/></svg>'.html_safe
  end

  def calendar_clock_icon
    '<svg viewbox="0 0 52 52" width="70" height="70"><use xlink:href="#calendar-clock"/></svg>'.html_safe
  end

  def calendar_exclamation_icon_lg
    '<svg viewbox="0 0 45 45" width="70" height="70"><use xlink:href="#calendar-exclamation"/></svg>'.html_safe
  end
  def calendar_exclamation_icon
    '<svg viewbox="0 0 52 52" width="50" height="50"><use xlink:href="#calendar-exclamation"/></svg>'.html_safe
  end

  def office_detail_icon
    '<svg viewbox="0 0 25 25" width="70" height="70"><use xlink:href="#office-o"/></svg>'.html_safe
  end

  def office_list_icon
    '<svg viewbox="0 0 25 25" width="60" height="60"><use xlink:href="#office-o"/></svg>'.html_safe
  end

  def office_review_icon
    '<svg viewbox="0 0 25 25" width="45" height="45"><use xlink:href="#office-o"/></svg>'.html_safe
  end

  def envelope_icon
    '<svg viewbox="0 0 25 25" width="25" height="25"><use xlink:href="#envelope"/></svg>'.html_safe
  end

  def om_envelope_icon
    '<svg viewbox="0 -4 23 20" width="25" height="25"><use xlink:href="#envelope"/></svg>'.html_safe
  end

  def phone_icon
    '<svg viewbox="0 0 25 25" width="25" height="25"><use xlink:href="#phone-circle-o"/></svg>'.html_safe
  end

  def drug_icon
    '<svg viewbox="3 0 25 25" width="25" height="25"><use xlink:href="#pill"/></svg>'.html_safe
  end

  def drug_circle_icon(width = 70, height = 70)
    r = '<svg viewbox="2 0 55 55" width="'+width.to_s+'" height="'+width.to_s+'"><use xlink:href="#pill-circle-o"/></svg>'
    r.html_safe
  end

  def angle_right_icon
    '<svg viewbox="0 0 25 25" width="25" height="25"><use xlink:href="#angle-right"/></svg>'.html_safe
  end

  def medical_bag_icon
    '<svg viewbox="0 0 40 40" width="45" height="45"><use xlink:href="#medical-bag"/></svg>'.html_safe
  end

  def user_icon
    '<svg viewbox="0 0 50 50" width="45" height="45"><use xlink:href="#agent-circle"/></svg>'.html_safe
  end

  def user_icon_xl
    '<svg viewbox="0 0 50 50" width="70" height="70"><use xlink:href="#agent-circle"/></svg>'.html_safe
  end

  def plus_circle_icon
    '<svg viewbox="0 0 25 25" width="45" height="45"><use xlink:href="#plus-circle-o-lite"/></svg>'.html_safe
  end

  def provider_plus_circle_icon
    '<svg viewbox="0 0 25 25" width="25" height="25"><use xlink:href="#plus-circle-o-lite"/></svg>'.html_safe
  end
  def provider_x_circle_icon
    '<svg viewbox="0 -2 25 25" width="25" height="25"><use xlink:href="#close-circle-o"/></svg>'.html_safe
  end

  def plus_circle_icon_om
    '<svg viewbox="4 0 21 21" width="70" height="70"><use xlink:href="#plus-circle-o-lite"/></svg>'.html_safe
  end

  def nav_angle_right_icon
    '<svg viewbox="0 0 15 15" width="15" height="15"><use xlink:href="#angle-right"/></svg>'.html_safe
  end

  def check_circle_open_icon
    '<svg viewbox="0 0 100 100" width="50" height="50"><use xlink:href="#check-circle-o"/></svg>'.html_safe
  end

  def bank_icon
    '<svg viewbox="0 0 52 52" width="70" height="70"><use xlink:href="#bank"/></svg>'.html_safe
  end

  def truck_icon
    '<svg viewbox="0 0 52 52" width="70" height="70"><use xlink:href="#truck"/></svg>'.html_safe
  end

end
