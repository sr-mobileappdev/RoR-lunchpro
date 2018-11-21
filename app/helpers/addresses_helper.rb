module AddressesHelper

  def single_line_address(addressable_object)
    return "" unless addressable_object && addressable_object.respond_to?(:address_line1)

    line_1 = [
      addressable_object.address_line1,
      addressable_object.address_line2,
      addressable_object.address_line3
    ].select(&:present?).join(" ")

    line_2 = [
      addressable_object.city,
      addressable_object.state
    ].select(&:present?).join(", ")

    if addressable_object.postal_code
      line_2 = "#{line_2} #{addressable_object.postal_code}"
    end

    [line_1, line_2].select(&:present?).join(" ")

  end

  def single_line_payment_address(addressable_object)
    return "" unless addressable_object && addressable_object.respond_to?(:address_line1)

    line_1 = [
      addressable_object.address_line1,
      addressable_object.address_line2
    ].select(&:present?).join(" ")

    line_2 = [
      addressable_object.city,
      addressable_object.state
    ].select(&:present?).join(", ")

    if addressable_object.postal_code
      line_2 = "#{line_2} #{addressable_object.postal_code}"
    end

    [line_1, line_2].select(&:present?).join(" ")

  end

end
