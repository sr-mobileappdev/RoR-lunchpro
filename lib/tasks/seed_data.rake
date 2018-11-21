namespace :seed_data do

  # !! These seed tasks are no longer in active use
  # ------

 #  task :all => :environment do
 #    CoreData.new().create_notifications

 #    return

 #    # -- Generate some fake offices

 #    addresses = [
 #        {address_line1: '3500 Keller Hicks Rd', city: 'Fort Worth', state: 'TX', postal_code: '76244'},
 #        {address_line1: '3550 Keller Hicks Rd', city: 'Fort Worth', state: 'TX', postal_code: '76244'},
 #        {address_line1: '11773 Bray Birch Dr', city: 'Fort Worth', state: 'TX', postal_code: '76244'},
 #        {address_line1: '12477 Timberland Blvd #633', city: 'Fort Worth', state: 'TX', postal_code: '76244'},
 #        {address_line1: '331 Golden Triangle Boulevard', city: 'Fort Worth', state: 'TX', postal_code: '76244'},
 #        {address_line1: '363 Keller Pkwy', city: 'Keller', state: 'TX', postal_code: '76248'},
 #        {address_line1: '620 S Main St #100', city: 'Keller', state: 'TX', postal_code: '76248'},
 #        {address_line1: '770 S Main St #430', city: 'Keller', state: 'TX', postal_code: '76248'},
 #        {address_line1: '10864 Texas Health Trail,', city: 'Fort Worth', state: 'TX', postal_code: '76244'},
 #        {address_line1: '9228 Sage Meadow Trail', city: 'Fort Worth', state: 'TX', postal_code: '76244'}
 #    ]
 #    Office.destroy_all
 #    offices = []
 #    (0...9).each do |counter|
 #      offices << {  name: Faker::Company.unique.name,
 #                    address_line1: addresses[counter][:address_line1],
 #                    city: addresses[counter][:city],
 #                    state: addresses[counter][:state],
 #                    postal_code: addresses[counter][:zip],
 #                    country: 'USA' }
 #    end
 #    offices = Office.create(offices)

 #    rests = [
 #        {name: 'Olive Garden', address_line1: '9333 Rain Lily Trail', city: 'Fort Worth', state: 'TX', postal_code: '76177', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Five Guys', address_line1: '9180 N Fwy Service Rd E', city: 'Fort Worth', state: 'TX', postal_code: '76177', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Elote Mexican Food Resturaunt', address_line1: '12584 N Beach St', city: 'Fort Worth', state: 'TX', postal_code: '76244', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Frescos Cocina', address_line1: '7432 Denton Hwy', city: 'Wataga', state: 'TX', postal_code: '76148', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'IHOP', address_line1: '3860 NE Loop 820', city: 'Fort Worth', state: 'TX', postal_code: '76137', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Chuck E Cheese', address_line1: '2755 E Grapevine Mills Cir', city: 'Grapevine', state: 'TX', postal_code: '76051', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Hard 8 BBQ', address_line1: '688 Freeport Pkwy', city: 'Coppell', state: 'TX', postal_code: '76019', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Funky Bahama\'s Kitchen', address_line1: '721 Keller Pkwy #100', city: 'Keller', state: 'TX', postal_code: '76248', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'FnG Eats', address_line1: '201 Town Center Ln #1101,', city: 'Keller', state: 'TX', postal_code: '76248', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Bronson Rock', address_line1: '250 S Main St', city: 'Keller', state: 'TX', postal_code: '76248', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10},
 #        {name: 'Tomatoes Mexican and Itallian', address_line1: '619 Ferris Ave', city: 'Waxahachie', state: 'TX', postal_code: '75165', country: 'USA', min_order_amount_cents: 10, max_order_people: 20, default_delivery_fee_cents: 10}
 #    ]
 #    Restaurant.destroy_all
 #    restaurants = Restaurant.create(rests)
 #    restaurants.each_with_index do |r, k|
 #      if k % 3 == 0
 #        dist = {radius: rand(2..10), use_complex: false}
 #      else
 #        dist = {radius: rand(2..10), use_complex: true, north: rand(1..10), north_east: rand(1..10), east: rand(1..10), south_east: rand(1..10), south: rand(1..10), south_west: rand(1..10), west: rand(1..10), north_west: rand(1..10)}
 #      end
 #      r.delivery_distance = DeliveryDistance.new(dist)
 #      r.save!
 #    end



 #    Provider.destroy_all
 #    providers = []
 #    (1...20).each do |counter|
 #      providers << { first_name: Faker::Name.first_name, last_name: Faker::Name.unique.last_name, title: "Dr." }
 #    end

 #    providers = Provider.create(providers)
 #    providers.each do |p|
 #      an_office = offices.sample
 #      an_office.providers << p
 #      an_office.save
 #    end


 #    SalesRep.destroy_all
 #    sales_reps = []
 #    (1...20).each do |counter|
 #      sales_reps << { first_name: Faker::Name.first_name,
 #                      last_name: Faker::Name.unique.last_name,
 #                      address_line1: Faker::Address.street_address,
 #                      city: Faker::Address.city,
 #                      state: Faker::Address.state,
 #                      postal_code: Faker::Address.zip,
 #                      country: Faker::Address.country }
 #    end
 #    sales_reps = SalesRep.create(sales_reps)


	# 	Rake::Task[ 'seed_data:slots' ].invoke
	# 	Rake::Task[ 'seed_data:appointments' ].invoke

 #  end#task:all



	# task :slots => :environment do
	# 	AppointmentSlot.destroy_all
	# 	slots = []
	# 	(1..200).each do
	# 		start_time = Tod::TimeOfDay(rand(8..17))
	# 		end_time = start_time + 1.hour
	# 		slots << {name: Faker::Hipster.word.titleize, day_of_week: rand(1..7), starts_at: start_time, ends_at: end_time, office: Office.all.sample, staff_count: rand(2..10), status: 'active'}
	# 	end
	# 	AppointmentSlot.create!(slots)
	# 	puts 'Appointment slots created.'
	# end#slots



	# task :appointments => :environment do
	# 	Appointment.destroy_all
	# 	appointments = []
	# 	AppointmentSlot.all.each do |slot|
	# 		appointments << {appointment_slot: slot, appointment_on: Date.today + rand(1..7), office: slot.office, appointment_type: 'standard', status: 'active', time_zone: 'America/Chicago'}
	# 	end
	# 	Appointment.create!(appointments)
	# 	puts 'Appointments created.'
	# end#appointments




end#seed_data
