module RestaurantHelper
  def restaurant_display_name(restaurant)
    return "" unless restaurant
    "#{restaurant.name} - #{restaurant.city}"
  end

  def restaurant_info(restaurant)
    return "" unless restaurant
    return restaurant.description if restaurant.description.present?
    single_line_address(restaurant)
  end

  def csv_restaurant_info(restaurant, admin = false)
    info = ""
    return info unless restaurant

    info += restaurant.name
    if admin
      manager = restaurant.users.active.first
      if manager
        info += "\n#{manager.display_name}"
        info += "\n#{manager.email}"
        info += "\n#{format_phone_number_string(manager.primary_phone)}"
      end
    end
    info.html_safe
  end

  def csv_restaurant_name(appt = nil, rest = nil)
    return nil if !appt && !rest
    if rest && !appt
      return rest.name
    end
    if appt.will_supply_food?
      "Bring Your Own: #{appt.bring_food_notes}"
    elsif appt.food_ordered && appt.csv_active_order
      appt.restaurant.name
    else
      "--"
    end
  end

  def csv_restaurant_poc_name(appt = nil, rest = nil)
    return nil if !appt && !rest
    if rest
      return rest.manager.display_name if rest.manager
      return "--"
    end
    if appt.food_ordered && appt.csv_active_order
      if appt.csv_active_order.restaurant.manager 
        appt.csv_active_order.restaurant.manager.display_name
      else
        "--"
      end
    else
      "--"
    end
  end

  def csv_restaurant_poc_email(appt = nil, rest = nil)
    return nil if !appt && !rest
    if rest
      return rest.manager.email if rest.manager
      return "--"
    end
    if appt.food_ordered && appt.csv_active_order      
      if appt.csv_active_order.restaurant.manager 
        appt.csv_active_order.restaurant.manager.email
      else
        "--"
      end
    else
      "--"
    end
  end

  def csv_restaurant_poc_phone(appt = nil, rest = nil)
    return nil if !appt && !rest
    if rest
      return format_phone_number_string(rest.manager.primary_phone) if rest.manager
      return "--"
    end
    if appt.food_ordered && appt.csv_active_order       
      if appt.csv_active_order.restaurant.manager 
        format_phone_number_string(appt.csv_active_order.restaurant.manager.primary_phone)
      else
        "--"
      end
    else
      "--"
    end
  end

  def restaurant_average_reviews(restaurant, type, include_average = false)
    return "" unless restaurant
    if type == :office_overall
      rating = restaurant.average_office_overall_rating
    else
      rating = restaurant.average_rating(type)
    end
    return "" unless rating
    html = '<fieldset class="order-rating rating-disabled d-inline">'
    5.downto(1) do |i|
      i = i.to_s
      if rating.to_i == i.to_i
        html += '<input type="radio" id="restaurant_' + restaurant.id.to_s + '_' + type.to_s + i + '" name="restaurant_' + restaurant.id.to_s + '_' + type.to_s + i + '" value="' + i + '"checked/><label for="quality' + i + '">' + i + ' stars</label>'
      else
        html += '<input type="radio" id="restaurant_' + restaurant.id.to_s + '_' + type.to_s + i + '" name="restaurant_' + restaurant.id.to_s + '_' + type.to_s + i + '" value="' + i + '"/><label for="quality' + i + '">' + i + ' stars</label>'
      end
    end
    html += '</fieldset>'
    if include_average
      html += '<a class="btn btn-link pr-0 pt-0 pl-1 ft-normal">(' + rating.to_s.gsub(/(\.)0+$/, '')+ ')</a>'
    end

    html.html_safe
  end

  def restaurant_average_on_time(restaurant, type = :on_time)
    return "" unless restaurant.present?
    average = restaurant.average_rating(type)
    return "" unless average.present?
    average.to_s + "\% On-Time Delivery"
  end
end
