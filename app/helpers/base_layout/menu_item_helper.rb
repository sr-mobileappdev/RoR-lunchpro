module BaseLayout::MenuItemHelper

  def menu_item_options_summary(menu_sub_items)
    if menu_sub_items.active.count == 0
      return "No Options".html_safe
    end

    html = ""
    menu_sub_items.active.each do |msi|
      html += "<span>#{msi.name} <span class='small' style='color: #aaa;'>#{msi.qty_allowed} Selections - #{msi.qty_required} Required</span></span><br/>"
      if msi.menu_sub_item_options.active.count > 0
        msi.menu_sub_item_options.active.each do |sub_i|
          html += "<span class='small'>#{sub_i.option_name}</span>"
          html += " <span class='small'>(#{precise_currency_value(sub_i.price_cents)} Charge)</span>" if sub_i.price_cents > 0
          html += "<br/>"
        end
      end

      html += "<br/>"
    end

    html.html_safe
  end

  def category_name(category)
    category.gsub("cat_", "").pluralize.humanize
  end

  def restaurant_price_range(restaurant)
    if restaurant.person_price_low && restaurant.person_price_high
      "$#{restaurant.person_price_low} - $#{restaurant.person_price_high}"
    else
      "Not Set"
    end
  end

  def person_price_range(price_range = [])
    "$#{price_range[0]} - $#{price_range[1]}"
  end

end
