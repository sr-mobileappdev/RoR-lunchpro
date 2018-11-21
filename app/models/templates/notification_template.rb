class Templates::NotificationTemplate < Templates::BaseTemplate
  attr_reader :notification

  def initialize(obj = nil)
    @object_type = obj.class
    @notification = obj
  end

  def tags
    {
      appointment: { appointment: Templates::AppointmentTemplate },
      sales_rep: { sales_rep: Templates::SalesRepTemplate },
      sales_rep_partner: {sales_rep_partner: Templates::SalesRepPartnerTemplate },
      office: { office: Templates::OfficeTemplate },
      restaurant: { restaurant: Templates::RestaurantTemplate },
      user: { user: Templates::UserTemplate },
      order: { order: Templates::OrderTemplate },
      appointment_slot: {appointment_slot: Templates::AppointmentSlotTemplate},
      order_transaction: {order_transaction: Templates::OrderTransactionTemplate},
      lunchpro_email: "lunchpro_email",
      lunchpro_phone: "lunchpro_phone",
      lunchpro_address: "lunchpro_address"
    }
  end

  def build(template_content)
    begin
      render(template_content, @notification)
    rescue Exception => ex
      Rollbar.error(ex)
    end
  end

  def __lunchpro_email
    'support@LunchPro.com'
  end

  def __lunchpro_phone
    '(855) 586-2477'
  end

  def __lunchpro_address
    'LunchPro, LLC ·  8111 LBJ Freeway · Suite 1460 · Dallas, Texas 75251'
  end
end
