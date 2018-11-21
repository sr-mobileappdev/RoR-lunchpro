module PaymentsHelper
  def card_fa(payment_method)
    case payment_method.cc_type
    when 'american_express'
      'fa-cc-amex'
    when 'visa'
      'fa-cc-visa'
    when 'mastercard'
      'fa-cc-mastercard'
    when 'discover'
      'fa-cc-discover'
    when 'jcb'
      'fa-cc-jcb'
    when 'diners_club'
      'fa-cc-diners-club'
    else
      'fa-credit-card'
    end
  end
end
