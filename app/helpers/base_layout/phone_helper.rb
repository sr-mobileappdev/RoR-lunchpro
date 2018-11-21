module BaseLayout::PhoneHelper

  def format_phone_number(phone = nil)
    return "" unless phone
    if phone.phone_number
      format_phone_number_string(phone.phone_number)
    else
      ""
    end
  end

  def format_phone_number_string(number = nil, return_nil = false)
    if return_nil
      return "" unless number && number.kind_of?(String)
    else
      return nil unless number && number.kind_of?(String)
    end

    if number.scan(/([\(|\)])/).count > 0
      number = number.gsub(/([\(|\)|\-])/, "").gsub(" ","")
    end

    pts = number.split("-")
    if pts.count == 3
      "(#{pts[0]}) #{pts[1]}-#{pts[2]}"
    elsif pts.count == 2
      "#{pts[1]}-#{pts[2]}"
    else
      if number.length == 10
        number_to_phone(number, area_code: true)
      elsif number.length == 11
        number_to_phone(number, area_code: true)
      elsif number.length == 12 || number.include?("+")
        number.gsub!("+","")
        "+#{number_to_phone(number, :groupings => [2, 3, 3, 4], :delimiter => "-")}"
      else
        "#{number}"
      end
    end
  end

end
