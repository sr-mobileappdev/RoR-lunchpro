class Managers::StatManager
  attr_reader :all_users
  attr_reader :all_orders
  attr_reader :all_appointments
  attr_reader :all_restaurants
  attr_reader :all_reps
  attr_reader :completed_orders
  attr_reader :office_users
  attr_reader :austin_offices
  attr_reader :dallas_offices


  def initialize()
    @mtd = Time.now.beginning_of_month..Time.now.end_of_day
    @ytd = Time.now.beginning_of_year..Time.now.end_of_day
    @wtd = Time.now.beginning_of_week..Time.now.end_of_week
    @last_month = Time.now.last_month.beginning_of_month..Time.now.last_month.end_of_month
    @last_60 = 60.days.ago..Time.now
    @last_30 = 30.days.ago..Time.now
    @next_90 = Time.now.beginning_of_day..90.days.from_now.end_of_day
    @all_orders = Order.joins(:appointment).includes(:appointment, :office, :restaurant).includes(:order_transactions).where("orders.status != 10 
      and appointments.appointment_on >= ?", Time.now.beginning_of_year)
    @all_users = User.where.not(status: 'deleted')
    @all_appointments = Appointment.includes(:appointment_slot, 
      :office).where("excluded != true and appointments.status != 10 and appointment_on >= ?", Time.now.beginning_of_year)
    @all_restaurants = Restaurant.where.not(status: 'deleted')
    @all_reps = SalesRep.includes(:orders, :appointments, :user).where.not(status: 'deleted')
    @completed_orders = @all_orders.select{|o| o.completed_at && o.funds_funded}
    @austin_offices = Office.near("Austin, TX", 100).to_a
    @dallas_offices = Office.where.not(:id => @austin_offices.pluck(:id))
    @office_users = UserOffice.includes(:office, :user).active

  end

### Monthly Active Users ###
# Rep (& Office?) User 'Active' Qualifications #
## Has booked or cancelled an appointment or ordered food in the last 30 days

  def office_mau
    @office_users.select{|ou| ou.user.sign_in_count > 0 && @last_30.include?(ou.user.last_sign_in_at)}.count
  end

  def office_mau_by_location(location)
    if location == 'Austin'
      @office_users.select{|ou| ou.user.sign_in_count > 0 && @last_30.include?(ou.user.last_sign_in_at) && ou.office && @austin_offices.include?(ou.office)}.count
    else
      @office_users.select{|ou| ou.user.sign_in_count > 0 && @last_30.include?(ou.user.last_sign_in_at) && ou.office && @dallas_offices.include?(ou.office)}.count
    end  
  end

  def rep_mau
    @all_reps.select{|rep| rep.is_active_user?}.count
  end

  def rep_mau_by_location(location) # Rep's do NOT have to provide an address, how do we tell which location they are for?
    @all_reps.select{|rep| rep.is_active_user?}.count
  end

  def total_appt_count #This is internal & non-internal
    @all_appointments.select{|a| a.active? && (a.appointment_on.today? || a.appointment_on.future?)}.count
  end

  def total_appt_count_by_location(location)
    if location == 'Austin'
      @all_appointments.select{|a| a.status == 'active' && (a.appointment_on.today? || a.appointment_on.future?) && a.office && @austin_offices.include?(a.office)}.count
    else
      @all_appointments.select{|a| a.status == 'active' && (a.appointment_on.today? || a.appointment_on.future?) && a.office && @dallas_offices.include?(a.office)}.count
    end  
  end

  def appointments_next_90 #all appointments for the next 90 days
    @all_appointments.select{|a| a.status == 'active' && @next_90.include?(a.appointment_on)}.count
  end

  def app_mau
# mobile? LunchPad? Web? All?
# how do I get the mobile user number?

  end


### Sales ###

  def revenue_mtd
    orders = @completed_orders.select{|o| @mtd.include?(o.appointment.appointment_on)} # completed orders that have not been refunded
    revenue = orders.map{|o| (o.commission_fee_cents || 0)}.sum

    revenue
  end

  def revenue_ytd
    orders = @completed_orders.select{|o| @ytd.include?(o.order_date)} # completed orders that have not been refunded
    revenue = 0
    revenue = orders.map{|o| (o.commission_fee_cents || 0)}.sum

    revenue
  end

  def sales_mtd
    orders = @completed_orders.select{|o| @mtd.include?(o.order_date)} # completed orders that have not been refunded
    sales = orders.map{|o| o.sales_amount_cents}.sum

    sales
  end

  def orders_mtd_by_location(location)
    if location == 'Austin'
      orders = @completed_orders.select{|o| @mtd.include?(o.appointment.appointment_on) && @austin_offices.include?(o.office)} # completed orders that have not been refunded
    else
      orders = @completed_orders.select{|o| @mtd.include?(o.appointment.appointment_on) && @dallas_offices.include?(o.office)} # completed orders that have not been refunded
    end 
    count = orders.size
    sales = orders.map{|o| o.sales_amount_cents}.sum

    return sales, count
  end

  def sales_last_month
    orders = @completed_orders.select{|o| @last_month.include?(o.order_date)} # completed orders that have not been refunded
    sales = orders.map{|o| o.sales_amount_cents}.sum

    sales
  end

  def sales_ytd
    orders = @completed_orders.select{|o| @ytd.include?(o.appointment.appointment_on)} # completed orders that have not been refunded
    sales = orders.map{|o| o.sales_amount_cents}.sum

    sales
  end

  def orders_ytd_by_location(location)
    if location == 'Austin'
      orders = @completed_orders.select{|o| @ytd.include?(o.appointment.appointment_on) && @austin_offices.include?(o.office)} # completed orders that have not been refunded
    else
      orders = @completed_orders.select{|o| @ytd.include?(o.appointment.appointment_on) && @dallas_offices.include?(o.office)} # completed orders that have not been refunded
    end    
    count = orders.size
    sales = orders.map{|o| o.sales_amount_cents}.sum

    return sales, count
  end

  def sales_per_day(weekday)  # sales for the given weekday in the current week
    date = Chronic.parse(weekday + ' of this week').to_date
    if date.future?
      sales = "--"
    else
      orders = @completed_orders.select{|o| date == o.appointment.appointment_on} # completed orders that have not been refunded
      sales = orders.map{|o| o.sales_amount_cents}.sum
    end

    sales
  end

  def sales_per_week(num_of_week) # sales for a week that was x amount of weeks ago
    week = num_of_week.weeks.ago.beginning_of_week.to_date..num_of_week.weeks.ago.end_of_week.to_date
    orders = @completed_orders.select{|o| week.include?(o.appointment.appointment_on)} # completed orders that have not been refunded
    sales = orders.map{|o| o.sales_amount_cents}.sum

    sales
  end

  def orders_today_by_location(location)
    orders = @all_orders.select{|o| o.status == 'active' && o.appointment.appointment_on == Time.now.to_date}
    count = orders.size
    sales = orders.map{|o| o.sales_amount_cents}.sum

    return sales, count
  end

  def orders_wtd_by_location(location)
    if location == 'Austin'
      orders = @completed_orders.select{|o| @wtd.include?(o.appointment.appointment_on) && @austin_offices.include?(o.office)} # completed orders that have not been refunded
    else
      orders = @completed_orders.select{|o| @wtd.include?(o.appointment.appointment_on) && @dallas_offices.include?(o.office)} # completed orders that have not been refunded
    end 
    count = orders.size
    sales = orders.map{|o| o.sales_amount_cents}.sum

    return sales, count
  end

### Usage Distribution Calculations ###

  def appt_dist # Stat. distribution of appointment based on slot type
    all_appointments = @all_appointments.where(cancelled_at: nil) # assuming cancelled appointments should not be included?

    distribution = Array.new
    AppointmentSlot.slot_types.each do |type, i|
      distribution << all_appointments.where(:appointment_slots => {slot_type: type}).count
    end

    distribution
  end


### This Week's table calcs ###

  def appt_count_day(weekday) # appointment count for a specific weekday of the current week
    date = Chronic.parse(weekday + ' of this week').to_date
    return @all_appointments.select{|a| a.appointment_on == date}.count
  end

  def appt_count_week(num_of_week) # appointment count for the week, x amount of weeks ago
    timeframe = Chronic.parse(num_of_week.to_s + ' weeks ago').beginning_of_week..Chronic.parse(num_of_week.to_s + ' weeks ago').end_of_week
    return @all_appointments.select{|app| timeframe.include?(app.appointment_on)}.count
  end

  def order_count_day(weekday) # order count for a specific weekday of the current week
    date = Chronic.parse(weekday + ' of this week').to_date
    return @all_orders.select{|o| o.appointment.appointment_on == date}.count
  end

  def order_count_week(num_of_week) # order count for the week, x amount of weeks ago
    timeframe = Chronic.parse(num_of_week.to_s + ' weeks ago').beginning_of_week..Chronic.parse(num_of_week.to_s + ' weeks ago').end_of_week
    return @all_orders.select{|o| timeframe.include?(o.appointment.appointment_on)}.count
  end

  def num_converted_day(weekday) # number of appointments with food ordered for an LP OFFICE
    date = Chronic.parse(weekday + ' of this week').to_date
    return @all_orders.select{|o| o.appointment.appointment_on == date && !o.office.creating_sales_rep_id.present? && o.created_by_user_id.present?}.count
  end

  def num_converted_week(num_of_week)
    timeframe = Chronic.parse(num_of_week.to_s + ' weeks ago').beginning_of_week..Chronic.parse(num_of_week.to_s + ' weeks ago').end_of_week
    return @all_orders.select{|o| timeframe.include?(o.appointment.appointment_on) && !o.office.creating_sales_rep_id.present? && o.created_by_user_id.present?}.count
  end


### Order-Related Calcs ###

  def declined_orders
    @all_orders.where(:status => 'inactive').where.not(:cancelled_by_id => nil).select{|order| User.find(order.cancelled_by_id).space == 'space_restaurant'}
  end

  def orders_placed_by_type # percentage
    mtd_orders = @all_orders.includes(:user).select{|o| @mtd.include?(o.delivery_date)}
    total_orders = mtd_orders.count
    orders_by_type = Array.new
    User.spaces.each do |type, i|
      orders_by_type << mtd_orders.select{|o| o.user && o.user.space == type}.count
    end
    orders_by_type.pop # remove onboarding
    orders_by_type.pop # remove restaurant, they can't place orders
    orders_by_type
  end

  def order_roles_labels
    labels = Array.new
    User.spaces.each do |s,i|
      labels << s.gsub("space_", "").humanize.titleize
    end
    labels.pop
    labels.pop
    labels
  end

  def orders_placed_by_user_level # this calculation is for users based off of how many orders they have placed
    mtd_orders = @all_orders.includes(:user).select{|o| @mtd.include?(o.created_at)}
    user_order_counts = mtd_orders.select{|o| o.user.present?}.map{|o| o.user.orders.count}
    num_of_orders = [1, (2..5), (6..10), 11] # change 11 to greater than 10
    orders_by_usage = Array.new
    num_of_orders.each do |level|
      if level.is_a?(Integer)
        if level == 11
          orders_by_usage << (user_order_counts.select{|o_count| o_count >= level}.count)
        else
          orders_by_usage << (user_order_counts.select{|o_count| o_count == level}.count)
        end
      else
        orders_by_usage << (user_order_counts.select{|o_count| level.include?(o_count)}.count)
      end
    end
    labels = ['First Order', '2 to 5', '6 to 10', '10+']


     return [orders_by_usage, labels]
  end

### MTD table ###

  def mtd_total_appointments
    @all_appointments.select{|a| @mtd.include?(a.appointment_on)}.count
  end

  def mtd_cancelled_appointments
    @all_appointments.select{|a| @mtd.include?(a.appointment_on) && (a.cancelled_at && @mtd.include?(a.cancelled_at))}.count
  end

  def mtd_new_users(space = nil)
    if space
      @all_users.select{|u| u.space == space && (u.confirmed_at.present? && @mtd.include?(u.confirmed_at)) || (u.invitation_accepted_at.present? && @mtd.include?(u.invitation_accepted_at))}.count # total amount of users activated this month, even if already deactivated
    else
      @all_users.select{|u| (u.confirmed_at.present? && @mtd.include?(u.confirmed_at)) || (u.invitation_accepted_at.present? && @mtd.include?(u.invitation_accepted_at))}.count
    end
  end

  def mtd_deactivated_users(space = nil)
    if space
      @all_users.select{|u| u.space == space && u.deactivated_at && @mtd.include?(u.deactivated_at)}.count
    else
      @all_users.select{|u| u.deactivated_at && @mtd.include?(u.deactivated_at)}.count
    end
  end

  def mtd_total_restaurants
    @all_restaurants.select{|r| r.activated_at && @mtd.include?(r.activated_at)}.count
  end

  def mtd_deactivated_restaurants
    @all_restaurants.select{|r| r.deactivated_at && @mtd.include?(r.deactivated_at)}.count
  end

  def net_mtd(type, space = nil)
    if type == 'user'
      if space
        net = mtd_new_users(space) - mtd_deactivated_users(space)
      else
        net = mtd_new_users - mtd_deactivated_users
      end
    elsif type == 'restaurant'
      net = (mtd_total_restaurants - mtd_deactivated_restaurants)
    elsif type == 'appointment'
      net = (mtd_total_appointments - mtd_cancelled_appointments)
    end

    if net.positive?
      net = '+' + net.to_s
    else
      net.to_s
    end

    return net

  end
end
