class Views::Search
  # Decoration / View methods for display of various details
  attr_reader :user_search

  def initialize(user_search)
    @user_search = user_search
  end

  def search_condition(key)
    if @user_search.conditions.present? && @user_search.conditions["wheres"]
      value_for_field_type(@user_search.conditions["wheres"][key])
    else
      nil
    end
  end

  def field_value_for(key = "")
    return "" unless key.present?
    if val = search_condition(key)
      return val
    else
      ""
    end
  end

  def value_for_field_type(value)
    if value.kind_of?(Hash)
      # Formatted value

    else
      "#{value}"
    end
  end

end
