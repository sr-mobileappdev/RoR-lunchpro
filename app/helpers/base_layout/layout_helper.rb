module BaseLayout::LayoutHelper

  def requires_ace?
    ace = false
    ace = true if @ace_editor

    ace
  end

  def title(title = nil)
    @page_title = title if title
    @page_title || "Home"
  end

  def tab(tab_value)
    @tab = tab_value
  end

  def tab_active?(tab_value)
    if @tab && @tab == tab_value
      "active"
    else
      ""
    end
  end

  def is_active_area?(controller)
    if controller.kind_of?(Array)
      if controller.include?(params[:controller].parameterize) || controller.include?("#{params[:action]}-#{params[:controller].parameterize}")
        "active"
      else
        ""
      end
    else
      if params[:controller].parameterize.include?("admin-#{controller}")
        "active"
      else
        ""
      end
    end
  end

  def cap_all_humanize(string)
    ret_string = ""
    unless string.blank?
      string = string.humanize
      ret_string = cap_all(string)
    end

    return ret_string
  end

  def cap_all(string)
    ret_string = ""
    unless string.blank?
      if string.downcase == "cid"
        ret_string = "CID"
      else
        ret_string = string.split.map(&:capitalize).join(' ')
        ret_string = ret_string.gsub("Id", "ID").gsub("Sms", "SMS").gsub("Cid", "CID")
      end
    end
    return ret_string
  end

  def cap(string)
    if string
      string.capitalize
    else
      string
    end
  end

  def currency_value(val)
    if val
      number_to_currency(val.to_f / 100.00, precision: 0)
    else
      ""
    end
  end

  def precise_currency_value(val, is_cents = true)
    if val
      number_to_currency((is_cents) ? (val.to_f / 100.00) : val, precision: 2)
    else
      "--"
    end
  end

  def precise_currency_or_nil(val, is_cents = true, convert_to_dollar = false)
    if val
      if convert_to_dollar
        number_to_currency((val.to_f / 100.00), precision: 2, unit: '')
      else
        number_to_currency((is_cents) ? (val.to_f / 100.00) : val, precision: 2, unit: '')
      end
    else
      nil
    end
  end

  def category_name(category)
    return "" unless category
    cap_all_humanize(category.gsub("cat_", ""))
  end

  def order_until_value(enum_val)
    return "" unless enum_val
    cap_all_humanize(enum_val.gsub("until_", ""))
  end

  def processing_fee_value(enum_val)
    return "" unless enum_val
    cap_all_humanize(enum_val.gsub("type_", ""))
  end

  def object_names_as_sentence(objects = nil)
    # Pass in an array of objects that respond to name or title and this will sentence-ify the list
    return "" unless objects
    if objects.count == 0
      ""
    elsif objects[0].respond_to?(:name)
      objects.map {|o| o.name }.flatten.compact.to_sentence
    elsif objects[0].respond_to?(:title)
      objects.map {|o| o.title }.flatten.compact.to_sentence
    else
      "~ Objects do not respond to name or title ~"
    end
  end

  def menu_summary(menu_item)
    "#{menu_item.name}<br/><span class='small'>#{menu_item.description.truncate(120)}</span>".html_safe
  end

  def radius_value(radius)
    return "" unless radius
    if radius && radius.kind_of?(String)
      radius
    else
      html = <<-HTML

        <div class='row'>
          <div class='col-4'>#{radius.north_west}m</div>
          <div class='col-4'>#{radius.north}m</div>
          <div class='col-4'>#{radius.north_east}m</div>
        </div>
        <div class='row'>
          <div class='col-4'>#{radius.west}m</div>
          <div class='col-4 offset-4'>#{radius.east}m</div>
        </div>
        <div class='row'>
          <div class='col-4'>#{radius.south_west}m</div>
          <div class='col-4'>#{radius.south}m</div>
          <div class='col-4'>#{radius.south_east}m</div>
        </div>

      HTML

      return html.html_safe

    end
  end

  def percentage_value(val)
    if val
      "#{val.to_f / 100.00}%"
    else
      ""
    end
  end

  def diet_restrictions_list(restrictions, default = "")
    html = ""
    if restrictions && restrictions.count > 0
      html = restrictions.map { |r| r.name }.flatten.compact.join("<br/>")
      return html.html_safe
    else
      if default.present?
        default.html_safe
      else
        ""
      end
    end
  end

  def user_office_link(object)
    return "" unless object.office
    "<a href='#{__path_to(object.office, {})}'>#{object.office.name}</a>".html_safe
  end

  def user_restaurant_link(object)
    return "" unless object
    "<a href='#{__path_to(object.restaurant, {})}'>#{object.restaurant.name}</a>".html_safe
  end

  def office_link(object)
    return "" unless object
    "<a href='#{__path_to(object, {})}'>#{object.name}</a>".html_safe
  end

  def restaurant_link(object)
    return "" unless object
    "<a href='#{__path_to(object, {})}'>#{object.name}</a>".html_safe
  end

  def sales_rep_link(object)
    return "" unless object

    if object.kind_of?(SalesRep)
      "<a href='#{__path_to(object, {})}'>#{object.display_name}</a>".html_safe
    elsif object.respond_to?(:sales_rep)
      "<a href='#{__path_to(object, {})}'>#{object.sales_rep.display_name}</a>".html_safe
    else
      ""
    end
  end

end
