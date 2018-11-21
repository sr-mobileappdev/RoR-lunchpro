class Restaurant < ApplicationRecord
	include LunchproRecord
  mount_uploader :brand_image, Managers::ImageUploaderManager

	belongs_to :created_by, class_name: 'User'

	has_and_belongs_to_many :cuisines

	has_many :restaurant_availabilities, dependent: :destroy
	has_many :restaurant_exclude_dates, dependent: :destroy
	has_many :restaurant_pocs, dependent: :destroy

  has_many :orders, dependent: :destroy
  has_many :menus, dependent: :destroy
  has_many :menu_items, dependent: :destroy
  has_many :lunch_packs, dependent: :destroy
  has_many :restaurant_pocs, dependent: :destroy

  has_many :user_restaurants, dependent: :destroy
  has_many :users, through: :user_restaurants

  has_many :bank_accounts, dependent: :destroy
  has_many :restaurant_transactions

  belongs_to :headquarters, class_name: 'Restaurant'
  has_many :restaurants, class_name: 'Restaurant', foreign_key: 'headquarters_id'


	has_one :delivery_distance, dependent: :destroy

  enum orders_until: { until_same_day: 1, until_1_day_before: 2, until_2_days_before: 3, until_3_days_before: 4 }
  enum processing_fee_type: { type_grand_total: 10, type_net_payout: 20}

	geocoded_by :geocodable_street_address   	# can also be an IP address
	after_validation :geocode          				# auto-fetch coordinates

  accepts_nested_attributes_for :restaurant_pocs, allow_destroy: true
  accepts_nested_attributes_for :restaurant_availabilities, allow_destroy: true
  accepts_nested_attributes_for :delivery_distance
	accepts_nested_attributes_for :restaurant_exclude_dates, allow_destroy: true
	accepts_nested_attributes_for :orders
  attr_accessor :average_rating, :average_on_time, :sales_rep
  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    unless name.present?
      self.errors.add(:base, "A name must be provided for this restaurant.")
    end

		unless address_line1.present?
			self.errors.add(:base, "A street address must be provided")
		end

		unless city.present?
			self.errors.add(:base, "The city must be provided")
		end

		unless state.present?
			self.errors.add(:base, "The zip code must be provided")
		end

		unless phone.present?
			self.errors.add(:base, "A phone number must be provided")
		end

		if self.new_record?
			self.timezone = Time.zone.name
			self.orders_until_hour = 5
		end

    if state.present?
      self.errors.add(:base, "Please enter a two character state abbreviation") if state.length != 2
      self.errors.add(:base, "Please enter a valid state abbreviation") if !states.include?(state.upcase)
      self.state = state.upcase
    end
  end

  def update_validations
    unless name.present? && phone.present?
      self.errors.add(:base, "A name and phone number must be provided for the restaurant.")
    end

    if state.present?
      self.errors.add(:base, "Please enter a two character state abbreviation") if state.length != 2
      self.errors.add(:base, "Please enter a valid state abbreviation") if !states.include?(state.upcase)
      self.state = state.upcase
    end
  end

  ## Logic for Headquarters/child ##
  def is_headquarters?
    !headquarters_id.present?
  end

  def is_active?
    self.activated_at.present? && !self.deactivated_at.present?
  end

  def manager
    users.select{|u| u.active?}.first
  end

  #list of active restaurant users
  def managers
    User.where(:id => user_restaurants.active.pluck(:user_id))
  end

	def orders_until_hour(local = false)
		return nil if !read_attribute(:orders_until_hour).present?
    if local
      timezone = self.timezone || Time.zone.name
      converted_time = (Tod::TimeOfDay.new(self.orders_until_hour).on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone)
      Tod::TimeOfDay(converted_time.to_s(:time)).hour
    else
      read_attribute(:orders_until_hour)
    end
  end

	def convert_times_to_utc
		self.orders_until_hour = Managers::TimeManager.new(Tod::TimeOfDay.new(self.orders_until_hour), nil, nil, restaurant.timezone).time_converted_to_utc if self.orders_until_hour_changed?
	end

  def orders_until_hour=(hour)
    self[:orders_until_hour] = Managers::TimeManager.new(hour, nil, nil, self.timezone).time_converted_to_utc
  end

  def orders_until_hour_local
    orders_until_hour(true)
  end

	def orders_until_hour_display
    return nil if !orders_until_hour
		time = Tod::TimeOfDay.parse "#{orders_until_hour_local}:00:00"
    "#{time.strftime('%l:%M %p')}"
	end

  def last_delivery
    order = past_orders.sort_by{|o| o.appointment.appointment_time(true)}.first
    if order
      order.appointment.appointment_time(true)
    end
  end

  def past_orders
    orders.select{|o| ['active', 'completed'].include?(o.status) && o.appointment && o.appointment.past?}
  end

  def upcoming_orders
    orders.select{|o| ['active'].include?(o.status) && o.appointment && o.appointment.upcoming?}
  end
  
  #this is used by the headquarters to grab list of consolidated orders for itself and children
  def consolidated_orders(order_status = 'active')
    return [] if !is_headquarters?  
    Order.joins(:appointment).includes(:appointment).where(:restaurant_id => (child_restaurants.pluck(:id) << id), :status => order_status, 
      :recommended_by_id => nil)
  end

  def orders_until_date_and_time(appointment)
    return nil if !appointment || !self.orders_until_hour.present?
    #if restaurant accepts order on day of appt, hard default threshhold of 3 hours prior
    if orders_until == "until_same_day"
      time = ((appointment.starts_at(true) - 3.hours).on (appointment.appointment_on - (Restaurant.orders_untils[self.orders_until] - 1).days))
    else
      if !(Restaurant.orders_untils[self.orders_until]) || !appointment.appointment_on 
        return nil
      end
      time = (Tod::TimeOfDay(self.orders_until_hour(true)).on (appointment.appointment_on - (Restaurant.orders_untils[self.orders_until] - 1).days))
    end
    time.asctime.in_time_zone(appointment.office.timezone)
  end

  def child_restaurants
    Restaurant.where(:status => 1, :headquarters_id => id)
  end

  def self.list_of_headquarters
    Restaurant.all.select{|rest| rest.is_headquarters?}.sort_by{|rest| rest.name}
  end

  def self.headquarters_list_for_admin(restaurant)
    self.list_of_headquarters.select{|r| r.id != restaurant.id}.collect{|r| ["#{r.name} - #{r.display_city_state_postal}", r.id]}
  end

  def self.child_restaurants_list_for_select(restaurant, restaurant_user)
    return [] if !restaurant_user || !restaurant
    restaurants = restaurant_user.restaurant.restaurants.active.to_a << restaurant_user.restaurant
    list = restaurants.select{|r| r.id != restaurant.id}.collect{|r| ["#{r.name} #{'(HQ)' if r.is_headquarters?} - #{r.display_location_single}", r.id]}
    #list << ['Consolidated Restaurants (See all orders and order history)', 'consolidated']
    list
  end

  def csv_name
    is_headquarters? ? "#{name} #{'(HQ)'}" : name
  end

  ## end ##
  def can_activate?
    activation_notices.count == 0
  end

  def fees_set?
    self.processing_fee_type.present? && self.late_cancel_fee_cents.present? && self.default_delivery_fee_cents
  end

	def order_limitations_set?
		self.orders_until.present? && self.orders_until_hour.present? && self.min_order_amount_cents.present? && self.max_order_people.present?
	end

  def order_reviews
    orders.map{|o| o.order_reviews.select{|rev| rev.active?}}.flatten(1)
  end

  def order_reviews_length
  	return order_reviews.length
  end

  #set default to 0 for sorting
  def average_rating(type, default = nil)
    reviews = order_reviews.to_a
    return default if !reviews.present?
    plucked_reviews = reviews.pluck(type).compact if type
    return default if !plucked_reviews.present?
    if type == :overall
      rating = (plucked_reviews.sum.to_f / plucked_reviews.size.to_f).to_f
    elsif type == :food_quality
      rating = (plucked_reviews.sum.to_f / plucked_reviews.size.to_f).to_f
    elsif type == :presentation
      rating = (plucked_reviews.sum.to_f / plucked_reviews.size.to_f).to_f
    elsif type == :completion
      rating = (plucked_reviews.sum.to_f / plucked_reviews.size.to_f).to_f
    elsif type == :on_time
      rep_reviews = reviews.select{|r| r.reviewer_type == 'SalesRep'}
      return default if !rep_reviews.present?
      on_time_count = rep_reviews.select{|r| r.on_time}.size.to_f
      total_count = rep_reviews.size.to_f
      rating = (on_time_count / total_count) * 100.0
    else
      rep_reviews = reviews.select{|r| r.reviewer_type == 'SalesRep'}
      rating = (rep_reviews.pluck(type).sum / rep_reviews.size).to_f if rep_reviews.present?
    end
    if !rating
      rating = 0
    end
    if type == :on_time
      rating.to_i
    else
      if rating < 1
        rating.ceil.round(1)
      else
        rating.round(1)
      end
    end
  end

  #virtual attribute for the average_overall_rating, used in sorting
  def average_overall_rating(default_nil = false)
    if default_nil
      average_rating(:overall, nil)
    else
      average_rating(:overall, 0)
    end
  end

	#virtual attribute for the average_office_overall_rating, used in RM view for reviews
	def average_office_overall_rating
		office_reviews = order_reviews.select{|rev| rev.reviewer_type == 'Office'}
		rating = (office_reviews.pluck(:overall).sum / office_reviews.size).to_f if office_reviews.present?
	end

  #virtual attribute for average on time percentage, used in sorting
  def average_on_time
    average_rating(:on_time, 0)
  end
  #virtual attribute for average of price_person_low and price_person_high
  def average_person_price
    begin
      (per_person_price_high + per_person_price_low).to_f / 2
    rescue Exception => ex
      raise ex
    end
  end

  #relevance calc as described in excel
  def relevance(rep = nil)
    raise "Must provide a sales rep" if !rep
    relevance = ((average_on_time / 100).to_f * average_overall_rating).to_f
    relevance = relevance - ((default_delivery_fee_cents.to_f / 100) / 20)

    rep_per_person = ((rep.per_person_budget_cents || 0) / 100).to_f
    if per_person_price_low <= rep_per_person
      relevance += 1
    else
      if per_person_price_low <= (rep_per_person * 1.2)
        relevance += 0.5
      end
    end
    relevance
  end

  def per_person_price_high
    person_price_high || 0
  end

  def per_person_price_low
    person_price_low || 0
  end

  #list of expected sort_by values, the :value needs to be exactly like this
  def self.sort_by_values
    [
      {value: 'relevance', name: 'Relevance'},
      {value: 'average_overall_rating^desc', name: "Average Rating (High to Low)"},
      {value: 'average_overall_rating^asc', name: "Average Rating (Low to High)"},
      {value: 'average_person_price^desc', name: "Price (High to Low)"},
      {value: 'average_person_price^asc', name: "Price (Low to High)"},
      {value: 'min_order_amount_cents desc', name: "Min Order (High to Low)"},
      {value: 'min_order_amount_cents asc', name: "Min Order (Low to High)"},
      {value: 'default_delivery_fee_cents desc', name: "Delivery Fee (High to Low)"},
      {value: 'default_delivery_fee_cents asc', name: "Delivery Fee (Low to High)"},
      {value: 'average_on_time^desc', name: "On Time (High to Low)"},
      {value: 'average_on_time^asc', name: "On Time (Low to High)"},
      {value: 'name asc', name: "Alphabetically"}
    ]
  end

  def notices
    @notices ||= Views::Notices.for_restaurant(self).all
  end

  def activation_notices
    @activation_notices ||= Views::Notices.for_restaurant(self).activation
  end

  def delivery_radius
    delivery_distance || DeliveryDistance.new(restaurant: self, radius: Constants::DEFAULT_DRIVING_DISTANCE)
  end

  def advanced_radius?
    delivery_distance && delivery_distance.use_complex == true
  end

  # number of orders this customer has competed at this restaurant
  def order_number(customer, order)
    self.orders.select{|order| order.appointment && (order.is_past_order && order.completed?) && order.customer == customer}.count
  end
	# Restaurant's orders that have not been confirmed and are active
	def all_unconfirmed_orders
		self.orders.includes(appointment: [:office, :sales_rep]).includes(:office, restaurant: [:restaurant_pocs]).select{|order| !order.appointment.restaurant_confirmed && order.status == 'active'}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
	end

	# All orders that have been confirmed by restaurant, but have not yet been completed
	def confirmed_orders
		self.orders.select{|order| !order.recommended_by_id && order.appointment && order.appointment.restaurant_confirmed && order.status == 'active'}.sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
	end

  def menu_items_for(menu = nil)
    if menu.nil? # All Items
      {packs: lunch_packs, item_groups: items_by_group}
    else
      {packs: [], item_groups: items_by_group(menu)}
    end
  end

  def menu_name_for(menu = nil)
    if menu.nil? # All Items
      "Full Menu"
    else
      menu.name || "Menu"
    end
  end

  def consolidated_unconfirmed_orders
    consolidated_orders.where('recommended_by_id is null and restaurant_confirmed_at is null and appointments.appointment_on >= ? and orders.created_at <= ?',
      Time.now.utc.to_date, (Time.now.utc - 2.days)).sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
  end

  def consolidated_confirmed_orders
    consolidated_orders.where('recommended_by_id is null and restaurant_confirmed_at is not null').sort_by{|order| [order.appointment.appointment_on, order.appointment.starts_at(true)]}
  end

  #get orders that have been unconfirmed for at least 48 AND are in the future
  def unconfirmed_orders
    orders.select{|order| !order.recommended_by_id && order.active? && order.appointment &&
        !order.appointment.restaurant_confirmed && order.appointment.appointment_on.to_date >= (Time.now.utc.to_date) && order.created_at <= (Time.now.utc - 2.days)}.sort_by{|order|
      order.appointment.starts_at(true)}
  end

  #get today's orders
  def orders_for_today
    orders.joins(:appointment).where("orders.status = 1 and appointment_id is not null and appointments.appointment_on = ? ", Time.now.to_date).sort_by{|order|
      order.appointment.starts_at(true)}
  end

  #return menus that are active and have at least 1 ACTIVE item
  def active_menus
    Menu.active.joins(:menu_items).where(:restaurant_id => self.id, menu_items: {:status => 'active'}).uniq
  end

  #filtering out menus that arent available at the start of an appointment
  #expect time ot be a TimeOfDay object
  def filtered_menus_by_time(time = nil)
    menus = active_menus
    return menus if !time
    menus.select{|menu| Tod::Shift.new(Tod::TimeOfDay(menu.start_time), Tod::TimeOfDay(menu.end_time)).include?(Tod::TimeOfDay(time))}
  end

  def items_by_group(menu = nil)
    if menu.nil?
      menu_items.where(:status => 'active').group_by { |mi| "#{mi.category}" }
    else
      #menu.menu_items.where(:status => 'active').group_by { |mi| "#{mi.category}" }
      menu.menu_items.where(:status => 'active', :lunchpack => true).group_by { |mi| "#{mi.lunchpack(true)}" }.merge!(menu.menu_items.where(:status => 'active')
        .where.not(:lunchpack => true).group_by { |mi| "#{mi.category}" })
    end
  end

  def menu_sorted_categories(menu = nil, time = nil)
    categories = {}
    if menu
      categories = items_by_group(menu)

    #if no menu is specificied, full menu
    else
      #grab list of filtered_menus by appointments.starts_at
      menu_ids = filtered_menus_by_time(time).pluck(:id)
      categories["LunchPacks"] = menu_items.active.select{|item| item.is_lunchpack? && (!item.menus.active.any? || (menu_ids & item.menus.active.pluck(:id)).any?) }
      MenuItem.categories.each do |cat, id|
        #grab active menu items in each category
        menu_items = self.menu_items.where(:status => 'active', category: cat, :lunchpack => false)

        #filter menu to include items that DO NOT belong to a menu OR DO belong to a menu that is available for this time
        menu_items = menu_items.select{|item| !item.menus.active.any? || (menu_ids & item.menus.active.pluck(:id)).any? }
        categories[cat] = menu_items
      end

    end

    categories
  end

  def other_menu_items_for(menu)
    # Find items NOT yet in this menu
    exclude_ids = menu.menu_items.pluck(:id)
    menu_items.where.not(status: 'deleted').where.not(id: exclude_ids).order(name: :asc)
  end

  def recalculate_per_person_price_ranges
    # person_price_* are always set in rounded dollar values, represented in integer

    self.person_price_low = 10
    self.person_price_high = 13
    self.save

  end

  def self.get_restaurants_per_appointment(appointment)
  	if !appointment.starts_at.present? || !appointment.appointment_on.present?
  		return []
  	end
	start_date_time = Time.new(appointment.appointment_on.year, appointment.appointment_on.month, appointment.appointment_on.day, appointment.starts_at.hour, appointment.starts_at.minute, appointment.starts_at.second)

	start_date_time = Time.zone.local_to_utc(start_date_time)
	day_of_week = start_date_time.to_date.wday

	available_restaurant_bucket = Restaurant
	.left_outer_joins(:restaurant_availabilities, :restaurant_exclude_dates, :menus)
	.where("restaurant_availabilities.status = ? AND restaurant_availabilities.starts_at <= ? AND restaurant_availabilities.ends_at >= ? AND restaurant_availabilities.day_of_week = ?", Constants::STATUS_ACTIVE, appointment.starts_at.to_s, appointment.starts_at.to_s, day_of_week)
	.where("(restaurant_exclude_dates IS NULL) OR (NOT (restaurant_exclude_dates.starts_at <= ? AND restaurant_exclude_dates.ends_at >= ?))", start_date_time, start_date_time)
	.where("menus.status = ? AND menus.start_time <= ? AND menus.end_time >= ?", Constants::STATUS_ACTIVE, appointment.starts_at.to_s, appointment.starts_at.to_s)
	.where("restaurants.orders_until IS NOT NULL AND restaurants.orders_until_hour IS NOT NULL")
	.references(:restaurant_availabilities, :restaurant_exclude_dates, :menus)
	.distinct

	to_return = []
	available_restaurant_bucket.each do |r|
	 if Time.now.utc < (appointment.appointment_on - (Restaurant.orders_untils[r.orders_until] - 1).days) + r.orders_until_hour.hours
	 	to_return << r
	 end
	end
	return to_return
  end


	def self.find_in_range_to_office(office)
		return [] if office.try(:latitude).nil? || office.try(:longitude).nil?
		rests = []
		distance = ENV['DEFAULT_RESTAURANT_SEARCH_DISTANCE'] || 60
		box = Geocoder::Calculations.bounding_box([office.latitude, office.longitude], distance)
		Restaurant.where("status = ? and activated_at is not null", Constants::STATUS_ACTIVE).within_bounding_box(box).each do |b|
			if b.delivery_distance.nil?
				#rests << b
			else
				if b.delivery_distance.use_complex
					dir = Geocoder::Calculations.compass_point(b.bearing_to(office))
					bearing_direction = 0
					case dir
						when "N"
							bearing_direction = b.delivery_distance.north
						when "NE"
							bearing_direction = b.delivery_distance.north_east
						when "E"
							bearing_direction = b.delivery_distance.east
						when "SE"
							bearing_direction = b.delivery_distance.south_east
						when "S"
							bearing_direction = b.delivery_distance.south
						when "SW"
							bearing_direction = b.delivery_distance.south_west
						when "W"
							bearing_direction = b.delivery_distance.west
						when "NW"
							bearing_direction = b.delivery_distance.north_west
					end
					if b.distance_to(office) <= bearing_direction
						rests << b
					end
				else
					if b.delivery_distance.radius && b.distance_to(office) && (b.distance_to(office) <= b.delivery_distance.radius)
						rests << b
					end
				end
			end
		end
    rests
	end#find_in_range_to_office


  # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [], options = {})
    params = {}

    scope_strings.each do |scope|
      case scope
        when "active"
          params["status"] = "active"
        when "inactive"
          params["status"] = "inactive"
        when "for_office"
          params["id"] = options[:limit_to_ids] || []

        # when "recent"
        #   params["status"] = "inactive"
        #   params["created_at"] = {"operator" => "gt", "condition" => Time.now - 30.days }
      end
    end

    params
  end
  # --

  def primary_cuisine
    (cuisines.first) ? cuisines.first.name : ""
  end

	def self.cuisines
		cuisines = Array.new
		Cuisine.active.each do |cuisine|
			cuisines << cuisine.name
		end

		cuisines.sort_by{|c| c }
	end

  def display_name
    name + " - " + city
  end

  def has_cuisine(cuisine)
    @these_cuisines ||= self.cuisines
    @these_cuisines.include?(cuisine)
  end

  def display_location
    self.address_line2.blank? ? "#{self.address_line1}<br/>#{self.display_city_state_postal}".html_safe : "#{self.address_line1}, #{self.address_line2}, #{self.display_city_state_postal}".html_safe
  end

  def display_location_single
    self.address_line2.blank? ? "#{self.address_line1}, #{self.display_city_state_postal}".html_safe : "#{self.address_line1}, #{self.address_line2}, #{self.display_city_state_postal}".html_safe
  end

  def display_city_state_postal
    "#{self.city}, #{self.state} #{self.postal_code}"
  end

  def display_city_state
    "#{self.city}, #{self.state}"
  end

  def withholdings
    vals = []
    vals << "Hold Tip" if withhold_tip
    vals << "Hold Tax" if withhold_tax

    vals.join(", ")
  end

  def person_price_range
    [self.person_price_low, self.person_price_high]
  end

	def convert_to_cents(amount)
		amount = amount.to_i * 100
		return amount
	end

	def primary_contacts
		self.restaurant_pocs.find_by(primary: 'true')
	end

	def secondary_contact
		if primary_contacts
			users.where.not(email: self.primary_contacts.email).first
		end
	end

#---- API Helpers

  def restaurant_quick_info
    {id: id, name: name, city: city, cuisine: primary_cuisine, brand_image_url: brand_image_url}
  end

#----

#--- Manager or POC info

  def contact
    users.active.first || restaurant_pocs.select{|poc| poc.active? && poc.primary}.first || restaurant_pocs.active.first
  end

  def contact_name
    return nil if !contact
    contact.display_name
  end

  def contact_email
    return nil if !contact
    contact.email
  end

  def contact_phone
    return nil if !contact
    ApplicationController.helpers.format_phone_number_string(contact.try(:phone) || contact.try(:primary_phone))
  end

#----

  def self.__columns
    cols = {display_location_single: 'Location', display_location: 'Location', withholdings: 'Tax / Tip Witholding', is_headquarters?: 'Headquarters', headquarters_id: 'Headquarters'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

	def phone_valid?
		if phone.present? && (phone.lenth == 10)
			return true
		else
			return false
		end
	end

	def brand_image_url
		if self.brand_image.present?
			return self.brand_image.url
		end
		return nil
	end

	def serializable_hash(options)
		if !options.present?
  			options = Hash.new()
  		end
		if options[:except].present?
			options[:except] << "brand_image"
		else
			options[:except] = ["brand_image"]
		end
		if options[:methods].present?
			options[:methods] << "brand_image_url"
		else
			options[:methods] = ["brand_image_url"]
		end
		super
	end

	private

	def geocodable_street_address
		[address_line1, city, state, postal_code, country].compact.join(', ')
	end

end
