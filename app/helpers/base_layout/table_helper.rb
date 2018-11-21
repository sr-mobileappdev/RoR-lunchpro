module BaseLayout::TableHelper

  def relatable_notice_path(record)
    return "" unless record
    path = __path_to(record, {})
    if path.present?
      path
    else
      "javascript:alert('No related record found')"
    end
  end

  def show_admin_path_for_row(record, optional_params = {})
    return "" unless record

    path = __path_to(record, optional_params)
    if path.present?
      path
    else
      "javascript:alert('No record path found')"
    end
  end

  def value_for_table_column(record, column_name, helper = nil, default_value = nil)
    begin
      return "" unless record
      if column_name.include?(".")
        selector = column_name.split(".", 2)

        if record.respond_to?(selector[0])
          value_for_table_column(record.send(selector[0]), selector[1], helper, default_value)
        else
          return "-- Complex nested relationships not supported --"
        end
      else
        if record.respond_to?(column_name)
          resp = record.send(column_name.to_sym)
          if column_name.include?("__light")
            return "<span class='lp__status_dot #{resp}'></span>".html_safe
          end

          if column_name.include?("__flag")
            if resp == true
              return "<span class='oi oi-check'></span>".html_safe
            elsif resp == false
              return "".html_safe
            end
          end

          if resp.kind_of?(Date)

          elsif resp.kind_of?(DateTime)
            "#{resp.strftime('%b %-d, %Y')}".html_safe
          else
            if helper
              return default_value if (resp == nil && default_value)
              send(helper, resp).html_safe
            else
              return default_value if (resp == nil && default_value)
              "#{resp}".html_safe
            end
          end
        else
          ""
        end
      end
    rescue Exception => ex
      return "! #{ex.message}"
    end
  end

  def format_column_name_by_model(column_id, klass, title = nil)
    return "" unless klass
    return title if title

    if column_id.include?(".")
      klass = column_id.split(".")[0]
      column_id = column_id.split(".")[1]
    end

    begin
      model = klass.classify.constantize
      return format_column_name(column_id) unless model && model.respond_to?("__columns")
      columns = model.send("__columns")

      if columns[column_id.to_sym]
        format_column_name(columns[column_id.to_sym])
      else
        format_column_name(column_id)
      end

    rescue Exception => ex
      # Swallow exceptions
      return "--"
    end

  end

  def format_column_name(column_name)
    return "" unless column_name
    if column_name.downcase == "id"
      return "ID"
    else
      return cap_all(column_name.humanize)
    end
  end

  def class_for_table_column(column_name)
    if column_name.include?("__light")
      "col-light"
    elsif column_name.include?("__flag")
      "col-flag"
    elsif column_name.include?("_type")
      "col-type"
    elsif column_name.include?("_id") || column_name == "id" || column_name.include?(".id")
      "col-id"
    elsif column_name.include?("_cid") || column_name == "cid" || column_name.include?(".cid")
      "col-cid"
    elsif column_name.include?("__summary") || column_name == "notes" || column_name == "summary"
      "col-notes"
    else
      ""
    end
  end

  def url_for_object_key(record, key)
    return "" unless record && key

    options = {}
    if key.kind_of?(Array)
      key_array = key
      return "" unless key_array.count == 2
      options = key_array[1]
      key = key_array[0]
    end

    if key.include?(".")
      key_array = key.split(".")
      if record.respond_to?(key_array[0])
        record = record.send(key_array[0])
        key = key_array[1]
      else
        ""
      end
    end

    if key == "id"
      __path_to(record, options)
    elsif record.respond_to?(key.to_s)
      __path_to(record.send(key.to_s), options)
    else
      ""
    end
  end

  def url_for_action(path, object = nil)
    if path.include?("%3Cid%3E")
      if object
        path.gsub("%3Cid%3E", "#{object.id}")
      else
        "javascript:alert('No record path found, missing ID')"
      end
    else
      path
    end
  end

  def links_to_custom_actions(object, actions = [])
    return "" unless actions && actions.count > 0
    html = ""
    actions.each do |action|
      next unless action.present?
      if action.kind_of?(Hash)
        # For special options pass in: {"action_name" => {options: hash}}
        html += html_for_table_action(action.keys[0], object, action.values[0])
      else
        html += html_for_table_action(action, object, {})
      end
    end

    html.html_safe
  end

  def html_for_table_action(action, object, options = {})
    case action
      when "select_restaurant_for_order"
        return "" unless options && options[:office_id] && options[:appointment]
        url = edit_admin_office_order_path(options[:office_id], options[:appointment].current_order,
                                    appointment_id: options[:appointment],
                                    restaurant_id: object.id, step: 2)
        "<a href='#{url}' class='btn btn-primary btn-sm'>Select</a>"
    else
      ""
    end
  end

  def __traverse_object(object, selector)

  end

  def __path_to(record, optional_params = {})
    if record
      case record.class.to_s
        when "SalesRep"
          admin_sales_rep_path(record, optional_params)
        when "Company"
          admin_company_path(record, optional_params)
        when "Office"
          admin_office_path(record, optional_params)
        when "OfficesSalesRep"
          admin_sales_rep_office_path(record.sales_rep, record, optional_params)
        when "NotificationEvent"
          admin_notification_event_path(record, optional_params)
        when "Restaurant"
          admin_restaurant_path(record, optional_params)
        when "Appointment"
          admin_appointment_path(record, optional_params)
        when "Order"
          admin_order_path(record, optional_params)
        when "Provider"
          admin_provider_path(record, optional_params)
        when "User"
          admin_user_path(record, optional_params)
        when "Payment"
          admin_payment_path(record, optional_params)
        when "UserOffice"
          admin_office_path(record.office, optional_params)
        when "Drug"
          edit_admin_drug_path(record, optional_params)
        when "Company"
          edit_admin_company_path(record, optional_params)
        else
          ""
      end
    else
      ""
    end
  end


end
