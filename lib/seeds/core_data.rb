  class CoreData
    attr_reader :prod # Can be run in production?

    BASE_USER_EMAIL = ENV['DEV_ADMIN_EMAIL'] # "michael@collectivepoint.com"

    def initialize
      @prod = false
      @dummy_user = User.where(email: BASE_USER_EMAIL).first
      @start_date = Time.zone.now - 4.days

      @reps = []
      @offices = []
      @restaurants = []

    end

    def create_test_data
      # Creates a sample set of test data with appointments, offices and sales reps

      _clear_the_decks
      _seed_drugs
      _seed_test_users
      puts "** Step 2: Created users"
      _seed_test_offices
      puts "** Step 3: Created new offices"
      _seed_test_restaurants
      puts "** Step 4: Built up some restaurants"



    end

    def create_notifications
      #  "This cannot be run in production" if Rails.env.production? && @prod == false
      _seed_notification_events     # The events in the system that will trigger a notification
      _seed_notification_recipients # The recipient types for these events (office, sales rep, admin, etc)
    end

    def dummy_admin_notifications
      ev = []
      ne = NotificationEvent.where(category_cid: '101').first
      # raise "Need to create notification events before creating dummy notifications" unless ne
      ev << {user_id: @dummy_user.id, title: 'New Office Inquiry', notification_event_id: ne.id, priority: 1, notified_at: Time.zone.now }

      Notification.create(ev)
    end















    def _seed_notification_events
      NotificationEvent.destroy_all

      events = []
      events << {category_cid: '100', status: 1, internal_summary: 'Invite: Welcome to Lunchpro'}
      events << {category_cid: '101', status: 1, internal_summary: 'Office: Medical office fills out contact form for info online'}
      events << {category_cid: '102', status: 1, internal_summary: 'Office: Opens calendar'}
      events << {category_cid: '103', status: 1, internal_summary: 'Office: Cancels appointment WITHOUT attached order'}
      events << {category_cid: '104', status: 1, internal_summary: 'Office: Cancels appointment WITH attached order'}
      events << {category_cid: '105', status: 1, internal_summary: 'Office: Recommends an Order'}
      events << {category_cid: '106', status: 1, internal_summary: 'Office: Recommends a Cuisine'}
      events << {category_cid: '107', status: 1, internal_summary: 'Office: Recommends a Restaurant'}
      # events << {category_cid: '108', status: 1, internal_summary: 'Office: Changes password / passcode'}
      events << {category_cid: '109', status: 1, internal_summary: 'Office: Sends standby notification'}
      events << {category_cid: '110', status: 1, internal_summary: 'Office: Submits a sample request w/slots'}
      events << {category_cid: '111', status: 1, internal_summary: 'Office: Submits a sample request w/o slots'}
      events << {category_cid: '112', status: 1, internal_summary: 'Office: Books appointment for rep'}
      events << {category_cid: '113', status: 1, internal_summary: 'Office: Changes appt details (staff count or providers)'}
      events << {category_cid: '114', status: 1, internal_summary: 'Office: Adds new appointment slots'}
      events << {category_cid: '115', status: 1, internal_summary: 'Office: Adds a new provider'}
      events << {category_cid: '116', status: 1, internal_summary: 'Office: Leaves feedback on Order'}
      events << {category_cid: '117', status: 1, internal_summary: 'Office: Books internal appt'}
      events << {category_cid: '118', status: 1, internal_summary: 'Office: Blocks rep AND cancels all future appts'}
      events << {category_cid: '119', status: 1, internal_summary: 'Office: Orders food for themselves'}
      events << {category_cid: '120', status: 1, internal_summary: 'Office: Cancels order'}
      events << {category_cid: '121', status: 1, internal_summary: 'Office: Edits order'}
      events << {category_cid: '201', status: 1, internal_summary: 'Rep: Books appointment, NO LP Account'}
      events << {category_cid: '202', status: 1, internal_summary: 'Rep: Books appointment, LP Account'}
      events << {category_cid: '203', status: 1, internal_summary: 'Rep: Places order'}
      events << {category_cid: '204', status: 1, internal_summary: 'Rep: Cancels appointment WITH attached order'}
      events << {category_cid: '205', status: 1, internal_summary: 'Rep: Cancels appointment WITHOUT attached order'}
      events << {category_cid: '206', status: 1, internal_summary: 'Rep: Cancels Order'}
      events << {category_cid: '207', status: 1, internal_summary: 'Rep: Edits order'}
      events << {category_cid: '208', status: 1, internal_summary: 'Rep: Edits/Accepts order recommendation'}
      events << {category_cid: '209', status: 1, internal_summary: 'Rep: Creates Account'}
      events << {category_cid: '210', status: 1, internal_summary: 'Rep: Leaves order feedback'}
      events << {category_cid: '211', status: 1, internal_summary: 'Rep: Adjusts tip post delivery'}
      events << {category_cid: '212', status: 1, internal_summary: 'Rep: Changes password'}
      events << {category_cid: '213', status: 1, internal_summary: 'Rep: Send Partner Request'}
      events << {category_cid: '214', status: 1, internal_summary: 'Rep: Partner Request Accepted'}
      events << {category_cid: '215', status: 1, internal_summary: 'Rep: Downloads App and enables push notifications'}
      events << {category_cid: '301', status: 1, internal_summary: 'Rest: Declines order'}
      events << {category_cid: '302', status: 1, internal_summary: 'Rest: Update ACH info'}
      events << {category_cid: '303', status: 1, internal_summary: 'Rest: Completes online form for more info'}
      events << {category_cid: '401', status: 1, internal_summary: 'LP: Activates office account & merges with existing rep office'}
      events << {category_cid: '402', status: 1, internal_summary: 'LP: Send final receipt'}
      events << {category_cid: '403', status: 1, internal_summary: 'LP: Upcoming Appointments reminder'}
      events << {category_cid: '404', status: 1, internal_summary: 'LP: Upcoming Appointments reminder (no appointments)'}
      events << {category_cid: '405', status: 1, internal_summary: 'LP: Restaurant Activation'}
      events << {category_cid: '406', status: 1, internal_summary: 'LP: Today\'s orders'}
      events << {category_cid: '407', status: 1, internal_summary: 'LP: Orders to non-LP offices'}
      events << {category_cid: '408', status: 1, internal_summary: 'LP: Outstanding Unconfirmed Orders'}
      events << {category_cid: '409', status: 1, internal_summary: 'LP: Request for meal feedback from office'}
      events << {category_cid: '410', status: 1, internal_summary: 'LP: Notice that Office Calendar is at T - 2 weeks'}
      events << {category_cid: '411', status: 1, internal_summary: 'LP: Send rep appointment confirmation request'}
      events << {category_cid: '412', status: 1, internal_summary: 'LP: Creates Account / Begins Re-Activation for New Office'}
      events << {category_cid: '413', status: 1, internal_summary: 'LP: Creates Account / Begins Re-Activation for New Restaurant'}
      events << {category_cid: '414', status: 1, internal_summary: 'LP: Rep confirmation pending'}
      events << {category_cid: '415', status: 1, internal_summary: 'LP: Reminder for rep to indicate food status'}
      events << {category_cid: '416', status: 1, internal_summary: 'LP: Attach free-floating appt to existing rep account'}
      events << {category_cid: '417', status: 1, internal_summary: 'LP: Rep accounts merged into 1'}
      events << {category_cid: '418', status: 1, internal_summary: 'LP: Password reset triggered by admin (for any user type, including admin)'}
      events << {category_cid: '419', status: 1, internal_summary: 'LP: Deactivate User (office, rep or rest)'}
      events << {category_cid: '420', status: 1, internal_summary: 'LP: Send rep notice of appointment slot time change'}

      NotificationEvent.create(events)

    end

    def _clear_the_decks
      puts "** Clearing the decks of prior test data"
      users = User.where(last_name: 'Testuser')
      sales_reps = SalesRep.all
      offices = Office.all
      restaurants = Restaurant.all
      users.each do |u|
        u.user_notification_prefs.destroy_all
        u.destroy
      end

      sales_reps.each do |o|
        o.destroy
      end
      SalesRep.unscope(:where).where(status: 'deleted').destroy_all

      offices.each do |o|
        o.destroy
      end
      Office.unscope(:where).where(status: 'deleted').destroy_all

      restaurants.each do |o|
        o.destroy
      end
      Restaurant.unscope(:where).where(status: 'deleted').destroy_all

      Provider.all.each do |o|
        o.destroy
      end
      Provider.unscope(:where).where(status: 'deleted').destroy_all

      SalesRepPartner.all.each do |o|
        o.destroy
      end
      SalesRepPartner.unscope(:where).where(status: 'deleted').destroy_all

      puts "** Step 1: The deck is cleared"

    end

    def _seed_notification_recipients
      NotificationEventRecipient.destroy_all

      NotificationEvent.all.each do |ne|
        rec = []
        case ne.category_cid
          when "101"
            rec << {recipient_type: 'office', status: 1, title: 'Welcome to LunchPro', priority: 2}
            rec << {recipient_type: 'admin', status: 1, title: 'Attention - New Office Inquiry', priority: 1}
          when "102"
            rec << {recipient_type: 'sales_rep', status: 1, title: 'New Dates Available on LunchPro!', priority: 2}
          when "103"
            rec << {recipient_type: 'office', status: 1, title: 'Cancellation: ||*sales_rep.display_name*|| ||*sales_rep.company.name*||', priority: 2}
            rec << {recipient_type: 'sales_rep', status: 1, title: 'Cancellation: ||*office.name*||', priority: 2}
            rec << {recipient_type: 'admin', status: 1, title: 'Office Cancelled Rep Appointment', priority: 2}
          when "104"
            rec << {recipient_type: 'office', status: 1, title: 'Cancellation: ||*sales_rep.display_name*|| ||*sales_rep.company.name*||', priority: 2}
            rec << {recipient_type: 'sales_rep', status: 1, title: 'Cancellation: ||*office.name*||', priority: 2}
            rec << {recipient_type: 'admin', status: 1, title: 'Office Cancelled Rep Appointment w/ Order', priority: 1}
          when "105"
            rec << {recipient_type: 'sales_rep', status: 1, title: 'LunchPro Office Order Recommendation', priority: 2}
            rec << {recipient_type: 'admin', status: 1, title: 'Order Recommendation Submitted', priority: 1}
          when "106"
            rec << {recipient_type: 'sales_rep', status: 1, title: 'LunchPro Office Cuisine Recommendation', priority: 2}
            rec << {recipient_type: 'admin', status: 1, title: 'Cuisine Recommendation Submitted', priority: 1}
          when "107"
            rec << {recipient_type: 'sales_rep', status: 1, title: 'LunchPro Office Restaurant Recommendation', priority: 2}
            rec << {recipient_type: 'admin', status: 1, title: 'Restaurant Recommendation Submitted', priority: 1}
          when "109"
            rec << {recipient_type: 'sales_rep', status: 1, title: 'Urgent: Standy Appointment Available', priority: 2}
        end

        if rec.count > 0
          ne.notification_event_recipients = NotificationEventRecipient.create(rec)
          ne.save
        end
      end
    end

    def _seed_drugs
      Drug.destroy_all

      Drug.create(brand: 'Praxis', generic_name: 'Praxigenerone', status: 'active', created_by_id: @dummy_user.id)
      Drug.create(brand: 'Axelavier', generic_name: 'Axelaviereric', status: 'active', created_by_id: @dummy_user.id)
      Drug.create(brand: 'Aquasol', generic_name: 'Aquasolomenaphin', status: 'active', created_by_id: @dummy_user.id)
      Drug.create(brand: 'Byphodine', generic_name: 'Byphodinosal', status: 'active', created_by_id: @dummy_user.id)
      Drug.create(brand: 'Clovoritol', generic_name: 'Clovormenaphin', status: 'active', created_by_id: @dummy_user.id)
    end

    def _seed_test_users
      Company.where(name: ['Drugs Inc.','Pharma Inc.']).destroy_all

      company       = Company.create(name: 'Drugs Inc.', created_by_id: @dummy_user.id, status: 'active')
      company_two   = Company.create(name: 'Pharma Inc.', created_by_id: @dummy_user.id, status: 'active')

      user_data = [
            {first_name: 'Josh', last_name: 'Testuser', email: 'joshtest@test.com', phone_number: '2143640193'},
            {first_name: 'Robert', last_name: 'Testuser', email: 'robtest@test.com', phone_number: '8173375111'},
            {first_name: 'Linda', last_name: 'Testuser', email: 'lindatest@test.com', phone_number: '9728007272'},
          ]

      sales_rep_defaults = {default_tip_percent: 1200, max_tip_amount_cents: 2000, per_person_budget_cents: 1500, timezone: Constants::DEFAULT_TIMEZONE}


      user_rep        = User.create(user_data[0].except(:phone_number).merge({password: 'testpass', password_confirmation: 'testpass', space: 'space_sales_rep', invited_by: @dummy_user, invitation_accepted_at: Time.zone.now}))
      user_rep_two    = User.create(user_data[1].except(:phone_number).merge({password: 'testpass', password_confirmation: 'testpass', space: 'space_sales_rep', invited_by: @dummy_user, invitation_accepted_at: Time.zone.now}))
      user_rep_three  = User.create(user_data[2].except(:phone_number).merge({password: 'testpass', password_confirmation: 'testpass', space: 'space_sales_rep', invited_by: @dummy_user, invitation_accepted_at: Time.zone.now}))

      rep = SalesRep.create(user_data[0].except(:email, :phone_number).merge(sales_rep_defaults).merge({status: 'active', activated_at: Time.zone.now, created_by_id: @dummy_user.id, user_id: user_rep.id}))
      rep.update_attributes(address_line1: '5308 White Willow Dr', city: 'Fort Worth', state: 'TX', postal_code: '76244', country: 'US', company_id: company.id )
      rep.drugs_sales_reps << DrugsSalesRep.new(sales_rep_id: rep.id, drug_id: Drug.all.pluck(:id).sample, status: 'active')
      rep.save

      rep_two = SalesRep.create(user_data[1].except(:email, :phone_number).merge(sales_rep_defaults).merge({status: 'active', activated_at: Time.zone.now, created_by_id: @dummy_user.id, user_id: user_rep_two.id}))
      rep_two.update_attributes(address_line1: '423 S Main St', city: 'Grapevine', state: 'TX', postal_code: '76051', country: 'US', company_id: company.id )
      rep_two.drugs_sales_reps << DrugsSalesRep.new(sales_rep_id: rep_two.id, drug_id: Drug.all.pluck(:id).sample, status: 'active')
      rep_two.save

      rep_three = SalesRep.create(user_data[2].except(:email, :phone_number).merge(sales_rep_defaults).merge({status: 'active', activated_at: Time.zone.now, created_by_id: @dummy_user.id, user_id: user_rep_three.id}))
      rep_three.update_attributes(address_line1: '2905 E Southlake Blvd', city: 'Southlake', state: 'TX', postal_code: '76092', country: 'US', company_id: company_two.id )
      rep_three.drugs_sales_reps << DrugsSalesRep.new(sales_rep_id: rep_three.id, drug_id: Drug.all.pluck(:id).sample, status: 'active')
      rep_three.save

      # Build the default preferences
      prefs = UserNotificationPref.create!(user_id: user_rep.id, notifiable: nil, status: 'active')
      prefs.reset_to_default!

      prefs = UserNotificationPref.create!(user_id: user_rep_two.id, notifiable: nil, status: 'active')
      prefs.reset_to_default!

      prefs = UserNotificationPref.create!(user_id: user_rep_three.id, notifiable: nil, status: 'active')
      prefs.reset_to_default!

      # Emails
      email_defaults = {email_type: 'personal', status: 'active', created_by_id: @dummy_user.id}
      rep.sales_rep_emails << SalesRepEmail.create(email_defaults.merge({email_address: user_data[0][:email]}))
      rep.save

      rep_two.sales_rep_emails << SalesRepEmail.create(email_defaults.merge({email_address: user_data[1][:email]}))
      rep_two.save

      rep_three.sales_rep_emails << SalesRepEmail.create(email_defaults.merge({email_address: user_data[2][:email]}))
      rep_three.save

      # Phones
      phone_defaults = {phone_type: 'business', status: 'active', created_by_id: @dummy_user.id}
      rep.sales_rep_phones << SalesRepPhone.create(phone_defaults.merge({phone_number: user_data[0][:phone_number]}))
      rep.save

      rep_two.sales_rep_phones << SalesRepPhone.create(phone_defaults.merge({phone_number: user_data[1][:phone_number]}))
      rep_two.save

      rep_three.sales_rep_phones << SalesRepPhone.create(phone_defaults.merge({phone_number: user_data[2][:phone_number]}))
      rep_three.save

      @reps = [rep, rep_two, rep_three]

    end

    def _seed_test_offices

      default_office_data = {status: 'active', total_staff_count: 12, office_policy: 'N/A', food_preferences: 'N/A', delivery_instructions: 'N/A', timezone: Constants::DEFAULT_TIMEZONE, policies_last_updated_at: Time.zone.now, appointments_until: @start_date + 45.days}

      office_data = [
            {name: 'Medical Associates', specialty: 'Family Practice', address_line1: '2601 E State Hwy 114', city: 'Southlake', state: 'TX', postal_code: '76092'},
            {name: 'Franklin Health', specialty: 'Family Practice', address_line1: '1170 N Carroll Ave', address_line2: 'Suite 110', city: 'Southlake', state: 'TX', postal_code: '76092'},
            {name: 'Sherman & Partners', specialty: 'Dermatology', address_line1: '1111 S Main St', city: 'Grapevine', state: 'TX', postal_code: '76051'},
            {name: 'Family Doctors', specialty: 'Urgent Care', address_line1: '1150 Texan Trail', city: 'Grapevine', state: 'TX', postal_code: '76051'},
            {name: 'Wallace Family Medicine', specialty: 'Family Practice', address_line1: '1175 Municipal Way', city: 'Grapevine', state: 'TX', postal_code: '76051'},
            {name: 'Smith Medical', specialty: 'Sports Medicine', address_line1: '1295 S Main St', city: 'Grapevine', state: 'TX', postal_code: '76051'},
          ]

      office_data.each_with_index do |od, index|
        if index < 2
          @offices << Office.create(od.merge(default_office_data).merge(created_by_id: nil, creating_sales_rep_id: @reps.first.id))
          rep = @reps.first
          OfficesSalesRep.create!(sales_rep_id: rep.id, office_id: @offices.last.id, status: 'active', per_person_budget_cents: rep.per_person_budget_cents, notes: 'Just a few notes on this office, noted here.', created_by_id: nil)
        else
          @offices << Office.create(od.merge(default_office_data).merge(created_by_id: @dummy_user.id))
          if index > 4
            rep = @reps.last
            OfficesSalesRep.create!(sales_rep_id: rep.id, office_id: @offices.last.id, status: 'active', per_person_budget_cents: rep.per_person_budget_cents, notes: 'Just a few notes on this office, noted here.', created_by_id: @dummy_user.id)
          end
        end
      end

      providers_data = [
          {first_name: 'Larry', last_name: 'Gregerson', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Mary', last_name: 'Smith', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Susan', last_name: 'Wembley', specialty: 'Dermatology', title: 'Dr.', status: 'active'},
          {first_name: 'Lance', last_name: 'Erikson', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Morris', last_name: 'Williams', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Glenda', last_name: 'Frey', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Sara', last_name: 'McClusker', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Bob', last_name: 'Robins', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Andrea', last_name: 'Jones', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Garth', last_name: 'Arles', specialty: 'Sports Medicine', title: 'Dr.', status: 'active'},
          {first_name: 'Linda', last_name: 'Richards', specialty: 'Family Medicine', title: 'Dr.', status: 'active'},
      ]

      @offices.each_with_index do |office, index|

        if index == 0
          OfficesProvider.create(provider: Provider.create(providers_data[0]), office: office)
          OfficesProvider.create(provider: Provider.create(providers_data[1]), office: office)
        elsif index == 1
          OfficesProvider.create(provider: Provider.create(providers_data[2]), office: office)
          OfficesProvider.create(provider: Provider.create(providers_data[3]), office: office)
        elsif index == 2
          OfficesProvider.create(provider: Provider.create(providers_data[4]), office: office)
        elsif index == 3
          OfficesProvider.create(provider: Provider.create(providers_data[5]), office: office)
          OfficesProvider.create(provider: Provider.create(providers_data[6]), office: office)
          OfficesProvider.create(provider: Provider.create(providers_data[7]), office: office)
        else
          OfficesProvider.create(provider: Provider.create(providers_data[(index + 4)]), office: office)
        end

        _create_office_slots(office)

      end

    end

    def _create_office_slots(office)

    end

    def _seed_test_restaurants

      cuisines = Cuisine.destroy_all
      cuisines = [
        {name: 'Tex-Mex', status: 'active'},
        {name: 'French', status: 'active'},
        {name: 'Bar & Grill', status: 'active'},
        {name: 'Homestyle', status: 'active'},
        {name: 'Fusion', status: 'active'},
        {name: 'Italian', status: 'active'},
        {name: 'Steakhouse', status: 'active'},
        {name: 'BBQ', status: 'active'},
      ]

      cuisines = Cuisine.create(cuisines)

      default_restaurant_params = {min_order_amount_cents: 1000, max_order_people: 30, default_delivery_fee_cents: 1000}

      rests = [
          {cuisine: 'Italian', name: 'Olive Garden', address_line1: '301 W State Hwy 114', city: 'Grapevine', state: 'TX', postal_code: '76501', country: 'USA'},
          {cuisine: 'Tex-Mex', name: 'Elote Mexican Food Resturaunt', address_line1: '12584 N Beach St', city: 'Fort Worth', state: 'TX', postal_code: '76244', country: 'USA'},
          {cuisine: 'Tex-Mex', name: 'Frescos Cocina', address_line1: '7432 Denton Hwy', city: 'Wataga', state: 'TX', postal_code: '76148', country: 'USA'},
          {cuisine: 'Steakhouse', name: 'Ranch Steakhouse', address_line1: '2755 E Grapevine Mills Cir', city: 'Grapevine', state: 'TX', postal_code: '76051', country: 'USA'},
          {cuisine: 'BBQ', name: 'Hard 8 BBQ', address_line1: '688 Freeport Pkwy', city: 'Coppell', state: 'TX', postal_code: '76019', country: 'USA'},
          {cuisine: 'Fusion', name: 'FnG Eats', address_line1: '201 Town Center Ln #1101,', city: 'Keller', state: 'TX', postal_code: '76248', country: 'USA'},
          {cuisine: 'Homestyle', name: 'Bronson Rock', address_line1: '250 S Main St', city: 'Keller', state: 'TX', postal_code: '76248', country: 'USA'},
          {cuisine: 'Italian', name: 'Tomatoes Mexican and Italian', address_line1: '619 Ferris Ave', city: 'Waxahachie', state: 'TX', postal_code: '75165', country: 'USA'},
          {cuisine: 'Bar & Grill', name: 'BJ\'s Brewhouse', address_line1: '2201 E Southlake Blvd', city: 'Southlake', state: 'TX', postal_code: '76092', country: 'USA'},
          {cuisine: 'Tex-Mex', name: 'Torchy Tacos', address_line1: '2175 E Southlake Blvd', city: 'Southlake', state: 'TX', postal_code: '76092', country: 'USA'},
      ]

      restaurants = []
      rests.each do |re|
        r = Restaurant.create(re.except(:cuisine).merge(default_restaurant_params))
        r.cuisines << Cuisine.where(name: re[:cuisine]).first
        r.save
        restaurants << r
      end

      restaurants.each_with_index do |r, k|
        if k % 3 == 0
          dist = {radius: [5,10,15].sample, use_complex: false}
        else
          dist = {radius: [5,10,15].sample, use_complex: true, north: [5,10,15].sample, north_east: [5,10,15].sample, east: [5,10,15].sample, south_east: [5,10,15].sample, south: [5,10,15].sample, south_west: [5,10,15].sample, west: [5,10,15].sample, north_west: [5,10,15].sample}
        end
        r.delivery_distance = DeliveryDistance.new(dist)
        r.save!

        _build_menu_for(r, r.cuisines.first)
      end

    end

    def _build_menu_for(rest, style = nil)
      if style
        items = []
        menus = []
        case style.name
          when "Tex-Mex"
            items = _build_menu_texmex
          when "Italian"
            items = _build_menu_italian
            #items = _build_menu_italian
          when "Steakhouse"
            #items = _build_menu_steakhouse
          when "BBQ"
            #items = _build_menu_bbq
          when "Fusion"
            #items = _build_menu_fusion
          when "Homestyle"
            #items = _build_menu_homestyle
          when "Bar & Grill"
            #items = _build_menu_bargrill
          else
        end

        lunch = Menu.create!( name: 'Lunch',
                              start_time: Tod::TimeOfDay.parse("11am"),
                              end_time: Tod::TimeOfDay.parse("12pm"),
                              created_by_user_id: @dummy_user.id,
                              status: 'active',
                              restaurant_id: rest.id)

        items.each do |mi|
          mi[:restaurant_id] = rest.id
        end
        new_items = MenuItem.create!(items)
        new_items.each do |item|
          item.menus << lunch
          item.save
        end

      else

      end
    end

    def _build_menu_texmex
      default_item_params = set_default_item_params
      items = []
      # Appetizers
      items << {name: 'Chips & Queso', description: 'Our signature queso and a heaping pile of warm, fresh flour tortilla chips.', people_served: 4, retail_price_cents: 400, category: 'cat_appetizer'}.merge(default_item_params)
      items << {name: 'Flautas', description: 'Chicken wrapped in flour tortillas and fried to perfection.', people_served: 4, retail_price_cents: 700, category: 'cat_appetizer'}.merge(default_item_params)
      items << {name: 'Chili con Carne', description: 'Our wonderful queso, blending with fajita steak or beef.', people_served: 4, retail_price_cents: 649, category: 'cat_appetizer'}.merge(default_item_params)
      items << {name: 'Guacamole', description: 'Delicious, fresh avacados blended with tomatoes, onions and spices.', people_served: 4, retail_price_cents: 499, category: 'cat_appetizer'}.merge(default_item_params)
      items << {name: 'Chicken Quesadilla', description: 'Warmed chicken and cheese layered on a fresh flour tortilla, served with salsa and guacamole.', people_served: 4, retail_price_cents: 800, category: 'cat_appetizer'}.merge(default_item_params)

      # Entrees
      items << {name: 'Chicken Enchiladas', description: 'Delicious, fresh, farm-raised chicken wrapped in our signature flour tortillas and covered in queso blano.', people_served: 1, retail_price_cents: 899, category: 'cat_entree'}.merge(default_item_params)
      items << {name: 'Tacos al Carbon', description: 'Fajita steak cooked-to-order, along with lettuce, tomatoes and warm flour tortillas.', people_served: 1,  retail_price_cents: 1100, category: 'cat_entree'}.merge(default_item_params)

      items
    end

    def _build_menu_italian
      default_item_params = set_default_item_params
      items = []
      # Appetizers
      items << {name: 'Bruschetta', description: 'Bruschetta is an antipasto from Italy consisting of grilled bread rubbed with garlic and topped with olive oil and salt.', people_served: 4, retail_price_cents: 400, category: 'cat_appetizer'}.merge(default_item_params)
      items << {name: 'Antipasto', description: 'Traditional first course of a formal Italian meal. Typical ingredients of a traditional antipasto include cured meats, olives, peperoncini, mushrooms, anchovies, artichoke hearts.', people_served: 4, retail_price_cents: 700, category: 'cat_appetizer'}.merge(default_item_params)

      # Entrees
      items << {name: 'Spaghetti', description: 'Delicious spaghetti and red sauce.', people_served: 1, retail_price_cents: 899, category: 'cat_entree'}.merge(default_item_params)
      items << {name: 'Mushroom-Sausage Ragu', description: 'Sauteed mushrooms can make almost any inexpensive red wine taste better.', people_served: 1,  retail_price_cents: 1100, category: 'cat_entree'}.merge(default_item_params)

      items
    end

    def _build_menu_steakhouse

    end

    def _build_menu_bbq

    end

    def _build_menu_fusion

    end

    def _build_menu_homestyle

    end

    def _build_menu_bargrill

    end

    def set_default_item_params
      {status: 'active', modified_by_user_id: @dummy_user.id, published_at: Time.zone.now}
    end

  end
