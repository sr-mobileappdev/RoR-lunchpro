module OfficesHelper

  def icon_list_class(count = nil)
    if count && count >= 5
      "icon-list-many"
    else
      "icon-list"
    end
  end

  def csv_office_manager_name(office)
    return nil if !office
    if office.manager
      office.manager.display_name
    else
      "--"
    end
  end

  def csv_office_manager_email(office)
    return nil if !office
    if office.manager
      office.manager.email
    else
      "--"
    end
  end

  def csv_office_manager_phone(office)
    return nil if !office
    if office.manager
      format_phone_number_string(office.manager.primary_phone)
    else
      "--"
    end
  end

end
