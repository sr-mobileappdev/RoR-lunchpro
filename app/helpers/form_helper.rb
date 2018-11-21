  module FormHelper


  def link_to_add_fields(name, f, association, path, classes ='lp__add_child btn btn-link')
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(path + association.to_s.singularize + "_fields", f: builder)
    end
    link_to(name, '#', class: classes, data: {id: id, fields: fields.gsub("\n", "")})
  end

  def link_to_add_provider_availability(name, f, association, path, existing_child = nil, day_of_week = nil, current_user)
    #if existing child, assign new provider_availability.day_of_week to child.day_of_weel
    #else pass in the current iteration of day_of_weeks
    if !existing_child
      new_object = f.object.send(association).klass.new(:day_of_week => day_of_week, :_destroy => false, :created_by_id => current_user.id)
    else
      new_object = f.object.send(association).klass.new(:day_of_week => existing_child.object.day_of_week, :_destroy => false, :created_by_id => current_user.id)
    end
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(path + association.to_s.singularize + "_fields", s: builder, f: f)
    end
    link_to(name, '#', class: "lp__add_child", data: {id: id, fields: fields.gsub("\n", "")})
  end

  def selectable_day_enum(keys, string_to_remove = nil)
    return [] unless keys && keys.kind_of?(Hash)
    keys.map { |key, value| [cap_all(key.humanize), key] }
  end

  def selectable_enum(keys, string_to_remove = nil)
    return [] unless keys && keys.kind_of?(Hash)
    if string_to_remove.present?
      keys.map { |key, value| [cap_all(key.gsub(string_to_remove, "").humanize), key] }
    else
      keys.map { |key, value| [cap_all(key.humanize), key] }
    end
  end

  def selectable_list(keys, string_to_remove = nil)
    return [] unless keys && keys.kind_of?(Hash)
    if string_to_remove.present?
      keys.map { |key, value| [cap_all(key.gsub(string_to_remove, "").humanize), (value.present?) ? value : key] }
    else
      keys.map { |key, value| [cap_all(key.humanize), (value.present?) ? value : key] }
    end
  end

  def lp_end_timeframe_field(form, field_sym, label = "", increment_min = 30, value = nil,  style = {class: 'form-control form-control-sm'})

    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    elsif label == 'none'
      label = nil
    end
    options = {}
    if value.present?
      options = {selected: "#{value}:00:00"}
    end
    html = ""
    html = "<label>#{label}</label>" unless style[:hide_label]
    html += form.select field_sym, timeframe_options(increment_min).map { |t| [t[:display_time], t[:time]] }.compact, options, style

    html.html_safe

  end

  def lp_slot_timeframe_field(form, field_sym, label = "", increment_min = 30, value = nil,  style = {class: 'form-control form-control-sm'})

    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    elsif label == 'none'
      label = nil
    end
    options = {}
    if value.present?
      options = {selected: "#{value.to_s.gsub(/^0/,'')}"}
    end
    html = ""
    html = "<label>#{label}</label>" unless style[:hide_label]

    if style[:capitalize_time]
      html += form.select field_sym, timeframe_options(increment_min, nil, true).map { |t| [t[:display_time], t[:time].squish] }.compact, options, style
    else
      html += form.select field_sym, timeframe_options(increment_min, nil, true).map { |t| [t[:display_time], t[:time].squish] }.compact, options, style
    end

    html.html_safe

  end

  def lp_timeframe_field(form, fields, label = "", values = [], options = {})

    unless values && values.compact.count == 2
      values = [nil, nil]
    end

    return "" unless fields && fields.count == 2
    if label.blank?
      label = "Timeframe"
    end

    field_name = fields[0].to_s
    if form && form.object_name
      field_name = "#{form.object_name}[#{fields[0].to_s}]"
    end

    html = "<label>#{label}</label>" unless options[:hide_label]
    html += "<div class='comp__multi_time_select'>"
    html += "<select name='#{field_name}' class='form-control form-control-sm __first'>"


    if options[:captialize_time]
      timeframe_options(15, values[0], true).each_with_index do |o, index|
        html += "<option data-position='#{index + 1}' value='#{o[:time]}' #{(o[:is_current]) ? 'selected' : ''}>#{o[:display_time]}</option>"
      end
    else
      timeframe_options(15, values[0]).each_with_index do |o, index|
        html += "<option data-position='#{index + 1}' value='#{o[:time]}' #{(o[:is_current]) ? 'selected' : ''}>#{o[:display_time]}</option>"
      end
    end
    html += "</select>"

    html += "<div class='__ms_divider'></div>"

    field_name = fields[1].to_s
    if form && form.object_name
      field_name = "#{form.object_name}[#{fields[1].to_s}]"
    end

    html += "<select name='#{field_name}' class='form-control form-control-sm __second'>"

    timeframe_options(15, values[1]).each_with_index do |o, index|
      html += "<option data-position='#{index + 1}' value='#{o[:time]}' #{(o[:is_current]) ? 'selected' : ''}>#{o[:display_time]}</option>"
    end
    html += "</select>"
    html += "</div>"

    html.html_safe
  end



  def lp_hidden_field(form, field_sym, value = nil, options = {})
    html = ""
    if form
      html += form.hidden_field field_sym, options
    else
      html += hidden_field nil, field_sym, :value => value
    end

    html.html_safe
  end

  def lp_percentage_field(form, field_sym, label = "", value = nil, options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.gsub("_percent","").humanize)
    end
    if label == 'none'
      label = nil
      html = ""
    else
      html = "<label>#{label}</label>"
    end
    html += "<div class='lp__percentage_field'>" unless options[:no_div]

    options = {class: 'form-control form-control-sm', value: (value) ? number_with_precision(value.to_f / 100.00, precision: 2) : nil}.merge(options)
    html += form.number_field field_sym, options.merge({step: 'any'})
    html += "</div>" unless options[:no_div]

    html.html_safe

  end

  def lp_whole_percentage_field(form, field_sym, label = "", value = nil, options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.gsub("_percent","").humanize)
    end
    if label == 'none'
      label = nil
      html = ""
    else
      html = "<label>#{label}</label>"
    end
    html += "<div class='lp__percentage_field'>" unless options[:no_div]

    options = {class: 'form-control form-control-sm', value: (value) ? number_with_precision(value / 100.00).to_i : nil,
      min: "1", step: "1", onkeypress: "return event.charCode >= 48 && event.charCode <= 57"
    }.merge(options)
    html += form.number_field field_sym, options.merge({step: 'any'})
    html += "</div>" unless options[:no_div]

    html.html_safe

  end

  def lp_currency_field(form, field_sym, label = "", value = nil, options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.gsub("_cents","").humanize)
    end
    if label == 'none'
      label = nil
    end
    options = {class: 'form-control form-control-sm'}.merge(options)
    if value
      options[:value] = (value) ? number_with_precision(value.to_f / 100.00, precision: 2) : nil
    end
    html = ""
    html += "<label>#{label}</label>" unless options[:hide_label]
    if options[:inline_div]
      html += "<div class='lp__currency_field d-inline-block'>"
    else
      html += "<div class='lp__currency_field'>"
    end
    if form
      html += form.text_field field_sym, options
    else
      html += text_field("", field_sym, options)
    end
    html += "</div>"

    html.html_safe
  end


  def lp_number_currency_field(form, field_sym, label = "", value = nil, options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.gsub("_cents","").humanize)
    end
    if label == 'none'
      label = nil
    end
    options = {class: 'form-control form-control-sm'}.merge(options)
    if value
      options[:value] = (value) ? number_with_precision(value.to_f / 100.00, precision: 2) : nil
    end
    html = ""
    html += "<label>#{label}</label>" unless options[:hide_label]
    if options[:inline_div]
      html += "<div class='lp__currency_field d-inline-block'>"
    else
      html += "<div class='lp__currency_field'>"
    end
    if form
      html += form.number_field field_sym, options.merge({step: 'any'})
    else
      html += text_field("", field_sym, options)
    end
    html += "</div>"

    html.html_safe
  end

  def lp_email_field(form, field_sym, label = "")
    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    end

    html = "<label>#{label}</label>"
    html += form.text_field field_sym, {class: 'form-control form-control-sm'}

    html.html_safe
  end

  def lp_calendar_field(form, field_sym, label = "")
    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    end

    html = "<label>#{label}</label>"
    if form
      html += form.text_field field_sym, {class: 'form-control form-control-sm lp__calendar'}
    else
      html += text_field("", field_sym, {class: 'form-control form-control-sm lp__calendar'})
    end

    html.html_safe
  end

  def lp_text_field(form, field_sym, label = "", value = nil, options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    end
    if label == 'none'
      label = nil
    end
    options = {class: 'form-control form-control-sm'}.merge(options)
    if value
      options[:value] = "#{value}"
    end

    html = ""
    html += "<label>#{label}</label>" unless options[:hide_label]
    if options[:required_field] == true
      html += "<label class='required'></label>"
    end
    if form
      html += form.text_field field_sym, options
    else
      html += text_field("", field_sym, options)
    end

    html.html_safe
  end

  def lp_numeric_field(form, field_sym, label = "", options = {}, whole_number = false)
    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    end

    options = {class: 'form-control form-control-sm'}.merge(options)

    html = ""
    html = "<label>#{label}</label>" unless options[:hide_label]

    if whole_number
      options = {min: "1", step: "1", onkeypress: "return event.charCode >= 48 && event.charCode <= 57"
      }.merge(options)
    end

    if form
      html += form.number_field field_sym, options
    else
      html += number_field("", field_sym, options)
    end

    html.html_safe
  end

  def lp_text_area(form, field_sym, label = "", value = nil, options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    elsif label == 'none'
      label = nil
    end


    options = {class: 'form-control form-control-sm'}.merge(options)

    html = ""
    html = "<label>#{label}</label>" unless options[:hide_label]
    if form
      html += form.text_area field_sym, options
    else
      html += text_area("", field_sym, options)
    end

    html.html_safe
  end

  def lp_sm_text_area(form, field_sym, label = "", value = nil, options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    elsif label == 'none'
      label = nil
    end


    options = {class: 'form-control form-control-sm sm-text-area'}.merge(options)

    html = ""
    html = "<label>#{label}</label>" unless options[:hide_label]
    if form
      html += form.text_area field_sym, options
    else
      html += text_area("", field_sym, options)
    end

    html.html_safe
  end

  def lp_radio_field_inline(form, field_sym, label = nil, value = nil)
    if label.blank?
      label ||= cap_all(field_sym.to_s.humanize)
    end

    html = "<label class='lp__inline_check'>"
    if form
      html += form.radio_button field_sym, {class: 'form-control form-control-sm', selected: value}
    else
      html += radio_button("", field_sym, {class: 'form-control form-control-sm', selected: value})
    end

    html += "#{label}"
    html += "</label>"

    html.html_safe
  end

  def lp_check_field_inline(form, field_sym, label = nil, value = nil, options = {})
    if label.blank?
      label ||= cap_all(field_sym.to_s.humanize)
    end

    if options.key?(:add_space)
      html = "<label class='lp__inline_radio pr-3'>"
    else
      html = "<label class='lp__inline_radio'>"
    end

    options = {class: 'form-control form-control-sm', checked: value}.merge(options)
    if form
      html += form.check_box field_sym, options
    else
      html += check_box("", field_sym, options)
    end

    html += "<label>#{label}</label></label>" unless options[:hide_label]

    html.html_safe
  end

  def lp_check_field(form, field_sym, label = nil, value = nil, check_label = nil)
    if label.blank?
      label ||= cap_all(field_sym.to_s.humanize)
    end

    html = "<label #{(label.blank?) ? "style='padding-top: 34px; display: block;'" : ""}>#{label}"
    if form
      html += form.check_box field_sym, {class: 'form-control form-control-sm'}
    else
      html += check_box("", field_sym, {class: 'form-control form-control-sm'})
    end

    if check_label.present?
      html += "#{check_label}"
    end

    html += "</label>"

    html.html_safe
  end

  def lp_select_field(form, field_sym, label = "", select_values = [], options = {})
    if label.blank?
      label ||= cap_all(field_sym.to_s.humanize)
    end

    options[:class] ||= 'form-control form-control-sm'

    html = ""
    html = "<label>#{label}</label>" unless options[:hide_label]
    if options[:required_field] == true
      html += "<label class='required'></label>"
    end
    if form
      html += form.select field_sym, select_values, {}, {class: options[:class]}
    else
      html += select nil, field_sym, select_values, options, {class: options[:class]}
    end

    html.html_safe
  end

  def lp_timezone_select_field(form, field_sym, label = "", options = {})
    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    end

    options = {class: 'form-control form-control-sm'}.merge(options)
    html = ""
    html = "<label>#{label}</label>" unless options[:hide_label]
    html += form.time_zone_select field_sym, ActiveSupport::TimeZone.us_zones, {}, options

    html.html_safe

  end

  def lp_multi_object_field(form, field_sym, label = "", list_options = {}, value = nil, display_value = nil)

    if label.blank?
      label = cap_all(field_sym.to_s.humanize)
    end

    options = []
    data_url = ""
    if list_options[:url]
      data_url = "data-url=\"#{list_options[:url]}\""
    elsif list_options[:options]
      options = list_options[:options]
    end

    style_class = "form-control form-control-sm"
    if list_options[:style_class]
      style_class = list_options[:style_class]
    end

    placeholder = "Search"
    if list_options[:placeholder]
      placeholder = list_options[:placeholder]
    end

    html = "<label>#{label}</label>"
    html += "<div class='comp__object_field'>"
    html += "<div class='__loading'><div class='sp-loading right light'></div></div>"
    html += "<input #{data_url} type='text' name='autofield' class='#{style_class} __object_field' value='#{(display_value) ? display_value : "" }' placeholder='#{placeholder}'/>"

    if form
      html += form.hidden_field field_sym, {class: 'targ-field-value', value: (value) ? value : nil}
    else
      html += hidden_field("", field_sym, {class: 'targ-field-value', value: (value) ? value : nil})
    end

    html += lp_dropdown(options)

    html += "</div>"
    html.html_safe

  end

  # - Used by lp_mulit_object_field
  def lp_dropdown(options = [])

    option_lis = []
    options.each do |o|
      option_lis << <<-HTML
        <li data-value="#{o[0]}" data-id="#{o[1]}"><strong>#{o[0]}</strong></li>
      HTML
    end

    if option_lis.count > 0
      option_lis = option_lis.join("")
    else
      option_lis = ""
    end

    html = <<-HTML
      <div class='__select_list'>
        <ul>
          #{option_lis}
        </ul>
      </div>
    HTML

    html.html_safe
  end

  def timeframe_options(increment_min, selected_time = nil, capitalize = false)

    options = []

    time = Tod::TimeOfDay.parse "5am"
    end_time = Tod::TimeOfDay.parse "11pm"
    termination_time = Tod::TimeOfDay.parse "1am"
    t = time
    options << {time: "", display_time: "--:-- --"}
    loop do
      break if t > end_time || t <= termination_time
      if capitalize
        h = {time: "#{t.strftime('%k:%M:%S')}", display_time: "#{t.strftime('%l:%M %p')}"}
      else
        h = {time: "#{t.strftime('%k:%M:%S')}", display_time: "#{t.strftime('%l:%M%P')}"}
      end
      h[:is_current] = true if selected_time && selected_time.to_i == t.to_i
      options << h
      t = t + increment_min.minutes
    end

    options
  end
  end
