class Templates::NotificationWebTemplate < Templates::BaseTemplate
  attr_reader :notification

  def initialize(obj = nil)
    @object_type = obj.class
    @notification = obj
  end

  def tags
    {
      appointment: { appointment: Templates::Web::AppointmentTemplate },      
      office: { office: Templates::Web::OfficeTemplate },      
      sales_rep_partner: {sales_rep_partner: Templates::Web::SalesRepPartnerTemplate },      
      sales_rep: { sales_rep: Templates::Web::SalesRepTemplate },
      restaurant: { restaurant: Templates::Web::RestaurantTemplate },
      order: { order: Templates::Web::OrderTemplate }
    }
  end

  def build(template_content)
    begin
      render(template_content, @notification)
    rescue Exception => ex
      Rollbar.error(ex)
    end
  end

end
