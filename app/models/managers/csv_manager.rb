class Managers::CsvManager
  attr_reader :errors
  attr_reader :user
  attr_reader :order
  attr_reader :csv_data
  attr_reader :ah

  def initialize()
    @ah = ApplicationController.helpers   #initialize helpers for ease of access
    @errors = []
  end

  #used for rep web/ om web
  def generate_order_detail(order)
    return nil if !order
    begin
      csv_data = CSV.generate do |csv| 
        csv << ['Status', 'Order #', 'Delivery Date', 'Delivery Time', 'Restaurant', 'Delivery Address', 'Customer', 'Order Count', 'Subtotal $',
          'Tax $', 'Tip $', 'Delivery $', 'Total $', 'Payment Method'] 
        a = [ah.csv_order_status(order), "#{order.order_number}", order.appointment.appointment_on, ah.slot_time(order.appointment.starts_at(true)), 
          ah.csv_restaurant_info(order.restaurant), ah.csv_order_delivery_info(order), ah.csv_order_customer_info(order),
          order.total_items, ah.precise_currency_or_nil(order.subtotal_cents), ah.precise_currency_or_nil(order.sales_tax_cents), ah.precise_currency_or_nil(order.tip_cents),
          ah.precise_currency_or_nil(order.delivery_cost_cents), ah.precise_currency_or_nil(order.total_cents),
           order.payment_method ? order.payment_method.short_display_name : '--'].map(&:to_s)
        a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
        csv << a
      end 
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_upcoming_orders(user, rep_only = true)
    return [] unless user.space == 'space_admin'

    begin
      if rep_only
        orders = Order.upcoming(rep_only)
        csv_data = CSV.generate do |csv| 
          csv << ['Status', 'Order #', 'Delivery Date', 'Delivery Time', 'Restaurant Name', 'Restaurant POC Name', 'Restaurant POC Email', 'Restaurant POC Phone',
           'Office Name','Office Address', 'Office Phone', 'LP Office', 'Order Count', 'Rep Name', 'Rep Co', 'Rep Email', 'Rep Phone',
            'LP Rep', 'Admin', 'Order Placed Date', 'Order Placed Time', 
            'Subtotal $', 'Tax $', 'Est. Tip $', 'Delivery $', 'Est. Total $', 'Rep Order #', 'Coupon Code'] 
          orders.each do |order|    
            customer = order.customer
            a = [ah.csv_order_status(order), order.order_number, order.appointment.appointment_on, ah.slot_time(order.appointment.starts_at(true)), 
              order.restaurant.name, ah.csv_restaurant_poc_name(order.appointment), ah.csv_restaurant_poc_email(order.appointment),
              ah.csv_restaurant_poc_phone(order.appointment),
              order.appointment.office.name, order.appointment.office.display_location_single, ah.format_phone_number_string(order.appointment.office.phone),
              self.class.humanized_yes_no(!order.appointment.office.private__flag), order.total_items, 
              customer.display_name, customer.company_name, customer.email('business', false) || customer.user.email, 
              ah.format_phone_number_string((customer.phone_record || customer.user.primary_phone), true) || "--", self.class.humanized_yes_no(order.appointment.sales_rep && order.appointment.sales_rep.user),
              'To-do', ah.simple_date(order.created_at), ah.slot_time(order.created_at),
              ah.precise_currency_or_nil(order.subtotal_cents), ah.precise_currency_or_nil(order.sales_tax_cents),
              ah.precise_currency_or_nil(order.tip_cents),
              ah.precise_currency_or_nil(order.delivery_cost_cents), ah.precise_currency_or_nil(order.total_cents),
              Order.user_order_number(customer, order), '?'].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end 
      else

      end
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end

  end

  def generate_past_orders(user, rep_only = true)
    return [] unless user.space == 'space_admin'

    begin
      if rep_only
        orders = Order.past
        csv_data = CSV.generate do |csv| 
          csv << ['Status', 'Order #', 'Delivery Date', 'Delivery Time', 'Restaurant Name', 'Restaurant POC Name', 'Restaurant POC Email', 'Restaurant POC Phone',
           'Office Name','Office Address', 'Office Phone', 'LP Office', 'Rep Name', 'Rep Co', 'Rep Email', 'Rep Phone',
            'LP Rep', 'Admin', 'Order Placed Date', 'Order Placed Time', 'Rep Order #', 'Coupon Code', 'Order Count',
            'Subtotal $', 'Tax $', 'Tip $', 'Delivery $', 'Total $', 'LP Paid?', 'Wholesale Adj.', 'Retail Adj.', 'Staff Comments',
            'LP Commission', 'LP Processing', 'LP Retention', 'Rest. Payout', 'Rest. Retention'] 
          orders.each do |order|    
            customer = order.customer
            a = [ah.csv_order_status(order), order.order_number, order.appointment.appointment_on, ah.slot_time(order.appointment.starts_at(true)), 
              order.restaurant.name, ah.csv_restaurant_poc_name(order.appointment), ah.csv_restaurant_poc_email(order.appointment),
              ah.csv_restaurant_poc_phone(order.appointment),
              order.appointment.office.name, order.appointment.office.display_location_single, ah.format_phone_number_string(order.appointment.office.phone),
              self.class.humanized_yes_no(!order.appointment.office.private__flag), 
              customer.display_name, customer.company_name, customer.email('business', false) || customer.user.email, 
              ah.format_phone_number_string((customer.phone_record || customer.user.primary_phone), true) || "--",
              self.class.humanized_yes_no(order.appointment.sales_rep && order.appointment.sales_rep.user),
              'To-do', ah.simple_date(order.created_at), ah.slot_time(order.created_at), Order.user_order_number(customer, order), '',
              order.total_items, ah.precise_currency_or_nil(order.subtotal_cents), ah.precise_currency_or_nil(order.sales_tax_cents),
              ah.precise_currency_or_nil(order.tip_cents),
              ah.precise_currency_or_nil(order.delivery_cost_cents), ah.precise_currency_or_nil(order.total_cents), 'LP Paid?', 'Wholesale Adj.', 'Retail Adj.', 'Staff Comments',
              'LP Commission', 'LP Processing', 'LP Retention', 'Rest. Payout', 'Rest. Retention'].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end 
      else

      end
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end

  end

  def generate_order_reviews(user)
    return [] unless user.space == 'space_admin'

    begin
      order_reviews = OrderReview.active.sort_by{|review| review.created_at}
      csv_data = CSV.generate do |csv| 
        csv << ['Review Date', 'Appt Date', 'Restaurant Name', 'Order #', 'Type', 'Reviewer',
          'Rating', 'On-Time'] 
        order_reviews.each do |review|   
          a = [ah.simple_date(review.created_at), ah.simple_date(review.order.appointment.appointment_on),
            review.order.restaurant.name, review.order.order_number, review.reviewer.class.name,
            review.reviewer_name, "#{review.overall} stars", review.on_time_display].map(&:to_s)
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end
      end
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_past_appointments(user, rep_only = true)
   return [] unless user.space == 'space_admin'

    begin
      if rep_only
          appointments = Appointment.joins(:office).includes(:office, :restaurant, orders: [restaurant: [:users]]).includes(sales_rep: [:user, :sales_rep_phones, :sales_rep_emails, 
          :company]).includes(appointment_slot: [office: [providers: [:provider_availabilities]]]).where("appointments.status in (1, 7) and appointment_on <= ? 
          and appointments.sales_rep_id is not null", Time.now.to_date).select{|appt|
           appt.appointment_time_in_zone < Time.zone.now}.sort_by{|appt| [appt.appointment_on,appt.starts_at]}

        #appointments = Appointment.past.select{|appt| appt.sales_rep }
        csv_data = CSV.generate do |csv| 

        csv << ['Date', 'Time', 'Status', 'Rep Name', 'Rep Co', 'Rep Email', 'Rep Phone', 'LP Rep', 'Office Name','Office Address', 'Office Phone',
           'LP Office', 'Restaurant Name', 'Restaurant POC Name', 'Restaurant POC Email', 'Restaurant POC Phone',
            'Order #', 'Admin', 'Origin', 'Booked On', 'Booked At', 'Cancelled By', 'Reason', 'Cancelled On',
            'Appointment Type', 'Staff Count', 'Rep Order #', 'Rep Est.', 'Coupon Code']
          appointments.each do |appointment|
            rep = appointment.sales_rep
            a = [ah.simple_date(appointment.appointment_on), ah.slot_time(appointment.starts_at(true)), ah.csv_appointment_status(appointment),
              rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              self.class.humanized_yes_no(appointment.sales_rep && appointment.sales_rep.user), appointment.office.name, 
              appointment.office.display_location_single, ah.format_phone_number_string(appointment.office.phone),
              self.class.humanized_yes_no(!appointment.office.private__flag), ah.csv_restaurant_name(appointment), ah.csv_restaurant_poc_name(appointment),
              ah.csv_restaurant_poc_email(appointment), ah.csv_restaurant_poc_phone(appointment), appointment.csv_active_order.try(:order_number),
              appointment.origin, 'to-do', ah.simple_date(appointment.created_at), ah.slot_time(appointment.created_at), ah.csv_appointment_cancelled_by(appointment),
              ah.csv_appointment_cancellation_reason(appointment), ah.csv_appointment_cancelled_on(appointment), ah.csv_appointment_name(appointment),
              appointment.appointment_slot ? appointment.appointment_slot.total_staff_count : "NA", '?', '?', '?'].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end

      else

      end
      csv_data

    rescue Exception => ex
    
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_cancelled_appointments(user, rep_only = true)
    return [] unless user.space == 'space_admin'

    begin
      if rep_only
          appointments = Appointment.joins(:office).includes(:office, :restaurant, orders: [restaurant: [:users]]).includes(sales_rep: [:user, :sales_rep_phones, :sales_rep_emails, 
          :company]).includes(appointment_slot: [office: [providers: [:provider_availabilities]]]).where("appointments.status = 9 and appointment_on <= ? 
          and appointments.sales_rep_id is not null and appointments.cancelled_at is not null", Time.now.to_date).select{|appt|
           appt.appointment_time_in_zone < Time.zone.now}.sort_by{|appt| [appt.appointment_on,appt.starts_at]}

        #appointments = Appointment.past.select{|appt| appt.sales_rep }
        csv_data = CSV.generate do |csv| 

        csv << ['Date', 'Time', 'Status', 'Rep Name', 'Rep Co', 'Rep Email', 'Rep Phone', 'LP Rep', 'Office Name','Office Address', 'Office Phone',
           'LP Office', 'Restaurant Name', 'Restaurant POC Name', 'Restaurant POC Email', 'Restaurant POC Phone',
            'Order #', 'Admin', 'Origin', 'Booked On', 'Booked At', 'Cancelled By', 'Reason', 'Cancelled On',
            'Appointment Type', 'Staff Count', 'Rep Order #', 'Rep Est.', 'Coupon Code']
          appointments.each do |appointment|
            rep = appointment.sales_rep
            a = [ah.simple_date(appointment.appointment_on), ah.slot_time(appointment.starts_at(true)), ah.csv_appointment_status(appointment),
              rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              self.class.humanized_yes_no(appointment.sales_rep && appointment.sales_rep.user), appointment.office.name, 
              appointment.office.display_location_single, ah.format_phone_number_string(appointment.office.phone),
              self.class.humanized_yes_no(!appointment.office.private__flag), ah.csv_restaurant_name(appointment), ah.csv_restaurant_poc_name(appointment),
              ah.csv_restaurant_poc_email(appointment), ah.csv_restaurant_poc_phone(appointment), appointment.csv_active_order.try(:order_number),
              appointment.origin, 'to-do', ah.simple_date(appointment.created_at), ah.slot_time(appointment.created_at), ah.csv_appointment_cancelled_by(appointment),
              ah.csv_appointment_cancellation_reason(appointment), ah.csv_appointment_cancelled_on(appointment), ah.csv_appointment_name(appointment),
              appointment.appointment_slot ? appointment.appointment_slot.total_staff_count : "NA", '?', '?', '?'].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end

      else

      end
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_upcoming_appointments(user, rep_only = true)
    return [] unless user.space == 'space_admin'

    begin
      if rep_only
        appointments = Appointment.joins(:office).includes(:office, :restaurant, orders: [restaurant: [:users]]).includes(sales_rep: [:user, :sales_rep_phones, :sales_rep_emails, 
          :company]).includes(appointment_slot: [office: [providers: [:provider_availabilities]]]).where("appointments.status = 1 and appointment_on >= ? 
          and appointments.sales_rep_id is not null", Time.now.to_date).select{|a| a.upcoming?}.sort_by{|appt| [appt.appointment_on,appt.starts_at]}
        csv_data = CSV.generate do |csv| 

        csv << ['Date', 'Time', 'Status', 'Rep Name', 'Rep Co', 'Rep Email', 'Rep Phone', 'LP Rep', 'Office Name','Office Address', 'Office Phone',
           'LP Office', 'Restaurant Name', 'Restaurant POC Name', 'Restaurant POC Email', 'Restaurant POC Phone',
            'Admin', 'Origin', 'Appointment Type', 'Staff Count', 'Booked On', 'Booked At']

          appointments.each do |appointment|
            rep = appointment.sales_rep
            a = [ah.simple_date(appointment.appointment_on), ah.slot_time(appointment.starts_at(true)), ah.csv_appointment_status(appointment),
              rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              self.class.humanized_yes_no(appointment.sales_rep && appointment.sales_rep.user), appointment.office.name, 
              appointment.office.display_location_single, ah.format_phone_number_string(appointment.office.phone),
              self.class.humanized_yes_no(!appointment.office.private__flag), ah.csv_restaurant_name(appointment), ah.csv_restaurant_poc_name(appointment),
              ah.csv_restaurant_poc_email(appointment), ah.csv_restaurant_poc_phone(appointment), 'to-do', appointment.origin.humanize, ah.csv_appointment_name(appointment),
              appointment.appointment_slot ? appointment.appointment_slot.total_staff_count : "NA", ah.simple_date(appointment.created_at), 
              ah.slot_time(appointment.created_at)].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end

      else

      end
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_active_offices(user, lp = true)
    return [] unless user.space == 'space_admin'

    begin
      if lp
        offices = Office.select{|office| office.active? && !office.private__flag}.sort_by{|office| office.name}
        csv_data = CSV.generate do |csv| 
          csv << ['Office Name', 'POC Name', 'POC Email', 'POC Phone', 'Activated', 'Last Activity', 'Calendar Open To', 'LunchPad', 'Next 30',
            'Next 60', 'Next 90', '90+', 'Total #', 'Rep Count', 'Appt Slots', 'Staff Count', 'Provider Count'] 
          offices.each do |office|   
            a = [office.name, ah.csv_office_manager_name(office), ah.csv_office_manager_email(office), ah.csv_office_manager_phone(office), 
              ah.simple_date(office.activated_at) || '--', office.manager ? ah.simple_date(office.manager.updated_at) : '--', ah.simple_date(office.appointments_until) || '--', '?', office.appointments_in_range(30).count, 
              office.appointments_in_range(60).count, office.appointments_in_range(90).count, office.appointments_in_range('90+').count, office.future_appointments.count, 
              office.visiting_reps_count, office.appointment_slots.active.count, office.total_staff_count, office.providers.active.count].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end
      else 

      end
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_inactive_offices(user, lp = true)
    return [] unless user.space == 'space_admin'

    begin
      if lp
        offices = Office.select{|office| office.inactive? && !office.private__flag}.sort_by{|office| office.name}
        csv_data = CSV.generate do |csv| 
          csv << ['Office Name', 'POC Name', 'POC Email', 'POC Phone', 'Activated', 'Deactivated', 'Deactivated By',
            'Past Appt Total #', 'Future Appt'] 
          offices.each do |office|   
            a = [office.name, ah.csv_office_manager_name(office), ah.csv_office_manager_email(office), ah.csv_office_manager_phone(office), 
              ah.simple_date(office.activated_at) || '--', ah.simple_date(office.deactivated_at) || '--', 
              office.deactivated_by ? office.deactivated_by.email : '--', office.past_appointments.count, office.future_appointments(false).count].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end
      else 

      end
      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_active_reps(user)
    return [] unless user.space == 'space_admin'
    begin
      
      #reps = SalesRep.joins('left outer join "users" on "users"."id" = "sales_reps"."user_id"').includes(:user, :sales_rep_phones, 
      #  :sales_rep_emails, :offices_sales_reps).where("sales_reps.status = 1").order(:last_name, :first_name).limit(100)
      reps = SalesRep.joins('left outer join "users" on "users"."id" = "sales_reps"."user_id"').includes(:company, :drugs_sales_reps, :sales_rep_partners, :sales_rep_phones, 
        :sales_rep_emails, appointments: [:office]).includes(orders: [appointment: [:office]]).
      includes(offices_sales_reps: [:office]).includes(user: [:payment_methods]).where("sales_reps.status = 1").order(:last_name, :first_name)
      
      csv_data = CSV.generate do |csv| 
        csv << ['LP', 'Name', 'Company', 'Email', 'Phone', 'Sign-Up', 'Last Activity', 'Future Appts: Imported', 'Future Appts: LunchPad', 'Future Appts: Web', 
          'Future Appts: App', 'Total Future Appts #', 'Past Orders: Self', 'Past Orders: Admin', 'Total Past Orders #', 'Past Orders Total $', 'Default Per Person Budget $', 
          'Default Tip %', 'Tip Not To Exceed $', 'Payment Info?',
          '# of Partners', '# of My Offices', "Drugs Rep'd"] 
        reps.each do |rep|
          if rep.user_id 
            a = [true, rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              ah.simple_date(rep.user.created_at), 
              ah.simple_date(rep.updated_at), "?", "?", "?", "?", rep.upcoming_appointments.count, "?", "?", rep.past_orders.count, 
              ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents)) || "--", ah.precise_currency_or_nil(rep.per_person_budget_cents) || "--",
              "#{rep.default_tip_percent ? rep.default_tip_percent.to_s : '--'}", ah.precise_currency_or_nil(rep.max_tip_amount_cents), 
              self.class.humanized_yes_no(rep.user.payment_methods.select{|p| p.status == 'active'}.any?),
              rep.sales_rep_partners.select{|p| p.active? }.count, rep.csv_active_offices.count, ah.format_drugs(rep.drugs_sales_reps.to_a)].map(&:to_s)            
          else
              a = [false, rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              ah.simple_date(rep.created_at), 
              ah.simple_date(rep.updated_at), "?", "?", "?", "?", rep.upcoming_appointments.count, "?", "?", rep.past_orders.count, 
              ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents)) || "--", ah.precise_currency_or_nil(rep.per_person_budget_cents) || "--",
              "#{rep.default_tip_percent ? rep.default_tip_percent.to_s : '--'}", ah.precise_currency_or_nil(rep.max_tip_amount_cents), "n/a",
              rep.sales_rep_partners.select{|p| p.active? }.count, rep.csv_active_offices.count, ah.format_drugs(rep.drugs_sales_reps.to_a)].map(&:to_s)   
          end
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end        
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_inactive_reps(user)
    return [] unless user.space == 'space_admin'
    begin
      
      reps = SalesRep.joins('left outer join "users" on "users"."id" = "sales_reps"."user_id"').includes(:company, :drugs_sales_reps, :sales_rep_partners, :sales_rep_phones, 
        :sales_rep_emails, appointments: [:office]).includes(orders: [appointment: [:office]]).
      includes(offices_sales_reps: [:office]).includes(user: [:payment_methods]).where("sales_reps.status = 9").order(:last_name, :first_name)
      csv_data = CSV.generate do |csv| 
        csv << ['LP', 'Name', 'Company', 'Email', 'Phone', 'Sign-Up', 'Deactivated', 'Deactivated By', 'Past Appt Total #', 'Order Total #', 'Order Total $'] 
        reps.each do |rep|
          if rep.user_id 
            a = [true, rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--",
              ah.simple_date(rep.user.created_at), 
              ah.simple_date(rep.user.deactivated_at), rep.user.deactivated_by_id ? User.find(rep.user.deactivated_by_id).email : '--', rep.past_appointments.count, 
              rep.past_orders.count, ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents))].map(&:to_s)
          else
            a = [false, rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--",
              ah.simple_date(rep.created_at), 
              ah.simple_date(rep.deactivated_at), '--', rep.past_appointments.count, 
              rep.past_orders.count, ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents))].map(&:to_s)
          end
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_active_lp_reps(user, start_date = nil, end_date = nil, force = false)
    return [] unless user.space == 'space_admin'
    begin
      #if start and end date is provided, use that as date range
      if start_date && end_date
        date_range = start_date.to_date..end_date.to_date
      #else beginning of week to current date
      else
        start = ((Date.today) + (Date.today.wday - 6) * -1) - 7
        date_range = start.to_date..Date.today.to_date
      end
      reps = SalesRep.joins('left outer join "users" on "users"."id" = "sales_reps"."user_id"').includes(:company, :drugs_sales_reps, :sales_rep_partners, :sales_rep_phones,
        :sales_rep_emails, appointments: [:office]).includes(orders: [appointment: [:office]]).
      includes(offices_sales_reps: [:office]).includes(user: [:payment_methods]).where("sales_reps.status = 1").order(:last_name, :first_name).where.not("users.invitation_accepted_at IS NULL").select{|rep| date_range.cover?(rep.created_at)}

      csv_data = CSV.generate do |csv| 
        csv << ['Name', 'Company', 'Email', 'Phone', 'Sign-Up', 'Last Activity', 'Future Appts: Imported', 'Future Appts: LunchPad', 'Future Appts: Web', 
          'Future Appts: App', 'Total Future Appts #', 'Past Orders: Self', 'Past Orders: Admin', 'Total Past Orders #', 'Past Orders Total $', 'Default Per Person Budget $', 
          'Default Tip %', 'Tip Not To Exceed $', 'Payment Info?',
          '# of Partners', '# of My Offices', "Drugs Rep'd"] 
        reps.each do |rep|
          if rep.user_id 
            a = [rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              ah.simple_date(rep.user.created_at), 
              ah.simple_date(rep.updated_at), "?", "?", "?", "?", rep.upcoming_appointments.count, "?", "?", rep.past_orders.count, 
              ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents)) || "--", ah.precise_currency_or_nil(rep.per_person_budget_cents) || "--",
              "#{rep.default_tip_percent ? rep.default_tip_percent.to_s : '--'}", ah.precise_currency_or_nil(rep.max_tip_amount_cents), 
              self.class.humanized_yes_no(rep.user.payment_methods.select{|p| p.status == 'active'}.any?),
              rep.sales_rep_partners.select{|p| p.active? }.count, rep.csv_active_offices.count, ah.format_drugs(rep.drugs_sales_reps.to_a)].map(&:to_s)            
          else
              a = [rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              ah.simple_date(rep.created_at), 
              ah.simple_date(rep.updated_at), "?", "?", "?", "?", rep.upcoming_appointments.count, "?", "?", rep.past_orders.count, 
              ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents)) || "--", ah.precise_currency_or_nil(rep.per_person_budget_cents) || "--",
              "#{rep.default_tip_percent ? rep.default_tip_percent.to_s : '--'}", ah.precise_currency_or_nil(rep.max_tip_amount_cents), "n/a",
              rep.sales_rep_partners.select{|p| p.active? }.count, rep.csv_active_offices.count, ah.format_drugs(rep.drugs_sales_reps.to_a)].map(&:to_s)   
          end
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end        
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_active_non_lp_reps(user, start_date = nil, end_date = nil, force = false)
    return [] unless user.space == 'space_admin'
    begin
      #if start and end date is provided, use that as date range
      if start_date && end_date
        date_range = start_date.to_date..end_date.to_date
      #else beginning of week to current date
      else
        start = ((Date.today) + (Date.today.wday - 6) * -1) - 7
        date_range = start.to_date..Date.today.to_date
      end

      reps = SalesRep.joins('left outer join "users" on "users"."id" = "sales_reps"."user_id"').includes(:company, :drugs_sales_reps, :sales_rep_partners, :sales_rep_phones, 
        :sales_rep_emails, appointments: [:office]).includes(orders: [appointment: [:office]]).
      includes(offices_sales_reps: [:office]).includes(user: [:payment_methods]).where("sales_reps.status = 1").order(:last_name, :first_name).where.not("users.invitation_accepted_at IS NOT NULL").select{|rep| date_range.cover?(rep.created_at)}
      
      csv_data = CSV.generate do |csv| 
        csv << ['Name', 'Company', 'Email', 'Phone', 'Sign-Up', 'Last Activity', 'Future Appts: Imported', 'Future Appts: LunchPad', 'Future Appts: Web', 
          'Future Appts: App', 'Total Future Appts #', 'Past Orders: Self', 'Past Orders: Admin', 'Total Past Orders #', 'Past Orders Total $', 'Default Per Person Budget $', 
          'Default Tip %', 'Tip Not To Exceed $', 'Payment Info?',
          '# of Partners', '# of My Offices', "Drugs Rep'd"] 
        reps.each do |rep|
          if rep.user_id 
            a = [rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              ah.simple_date(rep.user.created_at), 
              ah.simple_date(rep.updated_at), "?", "?", "?", "?", rep.upcoming_appointments.count, "?", "?", rep.past_orders.count, 
              ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents)) || "--", ah.precise_currency_or_nil(rep.per_person_budget_cents) || "--",
              "#{rep.default_tip_percent ? rep.default_tip_percent.to_s : '--'}", ah.precise_currency_or_nil(rep.max_tip_amount_cents), 
              self.class.humanized_yes_no(rep.user.payment_methods.select{|p| p.status == 'active'}.any?),
              rep.sales_rep_partners.select{|p| p.active? }.count, rep.csv_active_offices.count, ah.format_drugs(rep.drugs_sales_reps.to_a)].map(&:to_s)            
          else
              a = [rep.display_name, rep.company_name, rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--", 
              ah.simple_date(rep.created_at), 
              ah.simple_date(rep.updated_at), "?", "?", "?", "?", rep.upcoming_appointments.count, "?", "?", rep.past_orders.count, 
              ah.precise_currency_or_nil(Order.sum_of_order_totals(rep.past_orders, :total_cents)) || "--", ah.precise_currency_or_nil(rep.per_person_budget_cents) || "--",
              "#{rep.default_tip_percent ? rep.default_tip_percent.to_s : '--'}", ah.precise_currency_or_nil(rep.max_tip_amount_cents), "n/a",
              rep.sales_rep_partners.select{|p| p.active? }.count, rep.csv_active_offices.count, ah.format_drugs(rep.drugs_sales_reps.to_a)].map(&:to_s)   
          end
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end        
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_active_restaurants(user)
    return [] unless user.space == 'space_admin'
    begin
      
      restaurants = Restaurant.active.sort_by{|rest| rest.csv_name}
      csv_data = CSV.generate do |csv| 
        csv << ['Restaurant Name', 'POC Name', 'POC Email', 'POC Phone', 'Activated', 'Last Delivery', 'Location', 'Order Count', 'Subtotal $', 'Tax $', 'Tip $', 'Total $',
          'Future Order Count', 'Rating Count', 'Quality', 'Avg Rep Presentation', 'Rating Completeness', 'On Time %', 'Avg Office Rating'] 
        restaurants.each do |rest|
          a = [rest.csv_name, ah.csv_restaurant_poc_name(nil, rest),
            ah.csv_restaurant_poc_email(nil, rest), ah.csv_restaurant_poc_phone(nil, rest), ah.simple_date(rest.activated_at),
            ah.simple_date(rest.last_delivery), rest.display_city_state, rest.past_orders.count, 
            ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :subtotal_cents)),
            ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :sales_tax_cents)),
            ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :tip_cents)),
            ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :total_cents)),
            rest.upcoming_orders.count, rest.order_reviews_length, rest.average_rating(:food_quality) || "NA",
            rest.average_rating(:presentation) || "NA", rest.average_rating(:completion) || "NA", 
            rest.average_rating(:on_time) || "NA", rest.average_office_overall_rating || "NA" ].map(&:to_s)
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end 
  end


  def generate_inactive_restaurants(user)
    return [] unless user.space == 'space_admin'
    begin
      
      restaurants = Restaurant.inactive.sort_by{|rest| rest.csv_name}
      csv_data = CSV.generate do |csv| 
        csv << ['Restaurant Name', 'POC Name', 'POC Email', 'POC Phone', 'Activated', 'Deactivated', 'Deactivated By', 'Location', 'Order Count', 'Subtotal $', 'Tax $', 'Tip $', 'Total $',
          'Rating Count', 'Avg Rating', 'On Time %'] 
        restaurants.each do |rest|
          a = [rest.csv_name, ah.csv_restaurant_poc_name(nil, rest),
            ah.csv_restaurant_poc_email(nil, rest), ah.csv_restaurant_poc_phone(nil, rest), ah.simple_date(rest.activated_at), ah.simple_date(rest.deactivated_at),
            rest.deactivated_by_id ? User.find(rest.deactivated_by_id).email : '--',
            rest.display_city_state, rest.past_orders.count, ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :subtotal_cents)),
            ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :sales_tax_cents)),
            ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :tip_cents)),
            ah.precise_currency_or_nil(Order.sum_of_order_totals(rest.past_orders, :total_cents)),
            rest.order_reviews_length, rest.average_overall_rating(true) || "NA", rest.average_rating(:on_time) || "NA"].map(&:to_s)
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_booked_appointments_food(user, start_date = nil, end_date = nil)
    return [] unless user.space == 'space_admin'
    begin
      #if start and end date is provided, use that as date range
      if start_date && end_date
        date_range = start_date.to_date..end_date.to_date
      #else beginning of week to current date
      else
        start = ((Date.today) + (Date.today.wday - 6) * -1) - 7
        date_range = start.to_date..Date.today.to_date        
      end
      
      appts = Appointment.joins(:office).includes(:office, :restaurant, orders: [restaurant: [:users]]).includes(sales_rep: [:user, :sales_rep_phones, :sales_rep_emails,
        :company]).includes(appointment_slot: [office: [providers: [:provider_availabilities]]]).where("appointments.status = 1 and appointments.sales_rep_id is not null and appointments.appointment_on in (?)", date_range)
      csv_data = CSV.generate do |csv| 
        csv << ['Appointment Date', 'Appointment Type', 'Sales Rep', 'Email', 'Phone', 'LP Rep', 'Office',
          'Phone', 'LP Office', 'Appt Status', 'Restaurant', 'Order #', 'Order Status']
        appts.each do |appointment|
          rep = appointment.sales_rep
          order = appointment.csv_active_order
          order = appointment.cancelled_order if !order && !appointment.will_supply_food?

          if order
            a = [appointment.appointment_on, ah.csv_appointment_name(appointment), rep.display_name,
              rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--",
              self.class.humanized_yes_no(rep.user), appointment.office.name,               
              ah.format_phone_number_string(appointment.office.phone),
              self.class.humanized_yes_no(!appointment.office.private__flag), ah.csv_appointment_status(appointment), ah.csv_restaurant_name(nil, order.restaurant),
                order.order_number, ah.csv_order_status(order)
              ].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          else
            a = [appointment.appointment_on,  ah.csv_appointment_name(appointment), rep.display_name,
              rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
              ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--",
              self.class.humanized_yes_no(rep.user), appointment.office.name,               
              ah.format_phone_number_string(appointment.office.phone),
              self.class.humanized_yes_no(!appointment.office.private__flag), ah.csv_appointment_status(appointment), ah.csv_restaurant_name(appointment),
                "--", '--'
            ].map(&:to_s)
            a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
            csv << a
          end
        end
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_consolidated_appointments_orders(user, rep_only = true)
    return [] unless user.space == 'space_admin'
    begin
      if rep_only
        appts = Appointment.joins(:office).includes(:office, :restaurant, orders: [restaurant: [:users]]).includes(sales_rep: [:user, :sales_rep_phones, :sales_rep_emails, 
          :company]).includes(appointment_slot: [office: [providers: [:provider_availabilities]]]).where("((appointments.status in (1,7)) or (appointments.status = 9 and
          appointments.cancelled_at is not null)) and appointments.sales_rep_id is not null")
        csv_data = CSV.generate do |csv| 
          csv << ['Date', 'Time', 'Sales Rep', 'Pharma Co', 'Email', 'Phone', 'LP Rep', 'Sign Up Date', 'Last Activity', 'Office',
            'Phone', 'Address 1', 'Address 2', 'City', 'State', 'Zip', 'LP Office', 'Appt Status', 'Appointment Type', 'Origin', 'Booked On', 'Booked At',
            'Restaurant', 'Order #', 'Order Status', 'Booked On', 'Booked At', 'Staff/Order Count', 'Food Subtotal $', 'Tax $', 'Tip $',
            'Delivery $', 'Grand Total $', 'Coupon code', 'Restaurant POC', 'POC Email', 'POC Phone', 'Admin']
          appts.each do |appointment|
            rep = appointment.sales_rep
            order = appointment.csv_active_order
            order = appointment.cancelled_order if !order && !appointment.will_supply_food?

            if order
              a = [appointment.appointment_on, ah.slot_time(appointment.starts_at(true)), rep.display_name, rep.company_name,
                rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
                ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--",
                self.class.humanized_yes_no(rep.user),
                rep.user ? ah.simple_date(rep.user.created_at) : "--", ah.simple_date(rep.updated_at), appointment.office.name,               
                ah.format_phone_number_string(appointment.office.phone), appointment.office.address_line1, appointment.office.address_line2,
                appointment.office.city, appointment.office.state, appointment.office.postal_code,
                self.class.humanized_yes_no(!appointment.office.private__flag), ah.csv_appointment_status(appointment), ah.csv_appointment_name(appointment), appointment.origin.humanize, 
                  ah.simple_date(appointment.created_at), ah.slot_time(appointment.created_at), ah.csv_restaurant_name(nil, order.restaurant),
                  order.order_number, ah.csv_order_status(order), ah.simple_date(order.created_at), ah.slot_time(order.created_at), 
                  appointment.appointment_slot ? appointment.appointment_slot.total_staff_count : '--',
                  ah.precise_currency_or_nil(order.subtotal_cents), ah.precise_currency_or_nil(order.sales_tax_cents),
                  ah.precise_currency_or_nil(order.tip_cents),
                  ah.precise_currency_or_nil(order.delivery_cost_cents), ah.precise_currency_or_nil(order.total_cents), 'todo',
                  ah.csv_restaurant_poc_name(nil, order.restaurant), ah.csv_restaurant_poc_email(nil, order.restaurant), 
                  ah.csv_restaurant_poc_phone(nil, order.restaurant),'?'
                ].map(&:to_s)
              a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
              csv << a
            else
              a = [appointment.appointment_on, ah.slot_time(appointment.starts_at(true)), rep.display_name, rep.company_name,
                rep.sales_rep_emails.select{|em| em.status == 'active' && email_type = 'business'}.pluck(:email_address).first, 
                ah.format_phone_number_string(rep.sales_rep_phones{|p| p.status == 'active' && p.phone_type == 'business'}.pluck(:phone_number).first, true) || "--",
                self.class.humanized_yes_no(rep.user),
                rep.user ? ah.simple_date(rep.user.created_at) : "--", ah.simple_date(rep.updated_at), appointment.office.name,               
                ah.format_phone_number_string(appointment.office.phone), appointment.office.address_line1, appointment.office.address_line2,
                appointment.office.city, appointment.office.state, appointment.office.postal_code,
                self.class.humanized_yes_no(!appointment.office.private__flag), ah.csv_appointment_status(appointment), ah.csv_appointment_name(appointment), appointment.origin.humanize, 
                  ah.simple_date(appointment.created_at), ah.slot_time(appointment.created_at), ah.csv_restaurant_name(appointment),
                  "--", '--', "--", "--", "--",
                  "--","--",
                  "--",
                  "--", "--", 'todo',
                  "--", "--", 
                  "--",'?'
              ].map(&:to_s)
              a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
              csv << a
            end
          end
        end
      else

      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  def generate_restaurant_weekly_payout(user, start_date = nil, end_date = nil, force = false)
    return [] unless (user && user.space == 'space_admin') || force
    begin
      #if start and end date is provided, use that as date range
      if start_date && end_date
        date_range = start_date.to_date..end_date.to_date
      #else beginning of week to current date
      else
        start = ((Date.today) + (Date.today.wday - 6) * -1) - 7
        date_range = start.to_date..Date.today.to_date        
      end
      orders = Order.joins(:appointment).where("orders.status in (1,7) and appointments.appointment_on in (?)", date_range).includes(:office, :restaurant).
      includes(appointment: [:sales_rep]).order("appointments.appointment_on, appointments.starts_at")
      csv_data = CSV.generate do |csv| 
        csv << ['Order #', 'Order Date', 'Customer Name', 'Rest. Name', 'Food Subtotal', 'Coupon', 'Tax', 'Withold Tax', 'Tip', 'Delivery Fee',
          'Grand Total', 'Coupon Cost - LP', 'Coupon Cost - Rest', 'Commission', 'Processing Fee', 'Rest. Payout'] 
        orders.each do |order|
          a = [order.order_number, order.appointment.appointment_on, order.customer_name, order.restaurant.name, ah.precise_currency_or_nil(order.subtotal_cents, true, true).to_f,
            "todo", ah.precise_currency_or_nil(order.sales_tax_cents, true, true), self.class.humanized_yes_no(order.restaurant.withhold_tax), ah.precise_currency_or_nil(order.tip_cents, true, true),
            ah.precise_currency_or_nil(order.delivery_cost_cents, true, true), ah.precise_currency_or_nil(order.total_cents, true, true),
            "todo", "todo", ah.precise_currency_or_nil(order.calced_lunchpro_commission_cents, true, true), 
            ah.precise_currency_or_nil(order.calced_processing_fee_cents, true, true), ah.precise_currency_or_nil(order.net_payout, true, true) ].map(&:to_s)
          a = a.map {|o| o.gsub(o) {|a| a.present? ? a : "--"}}
          csv << a
        end
      end

      csv_data

    rescue Exception => ex
      @errors << ex
      Rollbar.error(ex)
    end
  end

  #send weekly report
  def send_weekly_payout_report
    SparkpostMailer.send_weekly_payout_report
  end

  def import_menu_items(user, restaurant_id, csv)
    return if !user || !restaurant_id || !csv || !user.space_admin? || !csv.content_type == 'text/csv'

    #list of col heads to check against each col iteration
    csv_cols = Import.menu_item_import_headers
    
    ActiveRecord::Base.transaction do
      begin
        csv_text = csv.read
        csv = CSV.parse(csv_text, :headers => true)
        col_count = 0
        incorrect_csv = false
        menu_items = []
        menu_item = nil
        menu_sub_item = nil
        menu_sub_item_option = nil
        current_obj = nil

        csv.each do |row|
          break if incorrect_csv  #if csv is not properly formatted
          col_count = 0
          row.each do |key, val|   
            if !val.present? && row.to_a.last.first != key #skip col iteration if no val
              col_count += 1
              next 
            end
            #used to ensure the column headers are set to what is expected, else break loop and rollback
            unless csv_cols[col_count][:csv_header] == key
              incorrect_csv = true
              break
            end

            case key
            when 'menu_item'
              if Import.yes_values.include?("#{val}".downcase)
                menu_item = MenuItem.new(:status => 'active', :modified_by_user_id => user.id, :restaurant_id => restaurant_id)
                current_obj = menu_item
              else
                incorrect_csv = true
              end
            when 'sub_menu_item'
              if Import.yes_values.include?("#{val}".downcase) && menu_item.present?
                menu_sub_item = MenuSubItem.new(:status => 'active')
                current_obj = menu_sub_item
              else
                incorrect_csv = true
              end
            when 'sub_menu_item_option'
              if Import.yes_values.include?("#{val}".downcase) && menu_sub_item.present?
                menu_sub_item_option = MenuSubItemOption.new(:status => 'active')
                current_obj = menu_sub_item_option
              else
                incorrect_csv = true
              end
            else
              #if val is category, set it to key val of enum
              if val
                val = MenuItem.categories.key(val.to_i) if key == 'category'
                current_obj.send(csv_cols[col_count][:db_header] + '=', val)    #set current obj attr to val
              end
            end

            #if last col in row, insert current obj to its respective array
            if row.to_a.last.first == key
              case current_obj.class.name
              when "MenuItem"
                menu_item = current_obj
                menu_items << current_obj
              when "MenuSubItem"
                menu_item.menu_sub_items << current_obj
              when "MenuSubItemOption"
                menu_sub_item.menu_sub_item_options << current_obj
              end
              current_obj = nil
            end          

            col_count += 1
          end
        end
        if incorrect_csv        
          raise ActiveRecord::Rollback
          return false
        else
          menu_items.each(&:save)
          return true
        end
      rescue Exception => ex
        Rollbar.error(ex)        
        raise ActiveRecord::Rollback
      end
      return false
    end
  end

  #export menu into menu_item csv
  def export_menu_items(user, restaurant_id, menu_id)
    begin
      return if !user || !restaurant_id || !menu_id
      restaurant = Restaurant.where(:id => restaurant_id).first
      menu = Menu.where(:id => menu_id).first
      return if !restaurant || !menu
      
      menu_items = menu.menu_items.active

      return if !menu_items.any?

      csv_data = CSV.generate do |csv| 
        csv << ['menu_item', 'sub_menu_item', 'sub_menu_item_option',  'name',  'description', 'price_cents', 'category',  'people_served', 'sub_options_qty_allowed', 'lunchpack']
        #loop through active menu items
        menu_items.each do |menu_item|
          csv << ['y', nil, nil, menu_item.name, menu_item.description, menu_item.retail_price_cents, MenuItem.categories[menu_item.category], menu_item.people_served, nil, menu_item.lunchpack]

          #loop through active sub menu items
          menu_item.menu_sub_items.active.each do |sub_menu_item|
            csv << [nil, 'y', nil, sub_menu_item.name, sub_menu_item.description, nil, nil, nil, sub_menu_item.qty_allowed, nil]

            #loop through active sub menu item options
            sub_menu_item.menu_sub_item_options.active.each do |sub_menu_item_option|
              csv << [nil, nil, 'y', sub_menu_item_option.option_name, nil, sub_menu_item_option.price_cents, nil, nil, nil, nil]
            end
          end
        end
      end
    rescue Exception => ex
      Rollbar.error(ex)        
      @errors << ex
    end

    csv_data
  end

  private

  def self.humanized_yes_no(bool)
    bool ? 'Yes' : 'No'
  end
end