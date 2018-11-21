##purpose of this manager is to handle background tasks related to orders
class Managers::OrderManager
  attr_reader :errors

  def initialize()
    @errors = []
  end

  #purpose is to prompt office to leave order feedback 24 hours after appointment end time
  #allow for 5 min offset


  def self.set_idempotency_keys
  	orders = Order.where(:status => 1, :idempotency_key => nil).select{|o| o.appointment && o.appointment.appointment_on >= Time.now.to_date}
  	orders.each do |o|
  		o.reset_idempotency_key
  	end
  end

private

end
