class RestaurantAvailability < ApplicationRecord
  include LunchproRecord
  attr_accessor :_destroy
  before_save :convert_times_to_utc
  serialize :starts_at, Tod::TimeOfDay
  serialize :ends_at, Tod::TimeOfDay

	belongs_to :restaurant

	enum dow: {monday: Constants::DOW_MONDAY, tuesday: Constants::DOW_TUESDAY, wednesday: Constants::DOW_WEDNESDAY, thursday: Constants::DOW_THURSDAY, friday: Constants::DOW_FRIDAY, saturday: Constants::DOW_SATURDAY, sunday: Constants::DOW_SUNDAY}

	validates_presence_of :restaurant
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def convert_times_to_utc
    self.starts_at = Managers::TimeManager.new(self.starts_at, nil, nil, restaurant.timezone).time_converted_to_utc if self.starts_at_changed?
    self.ends_at = Managers::TimeManager.new(self.ends_at, nil, nil, restaurant.timezone).time_converted_to_utc if self.ends_at_changed?
  end

  def create_validations
    if status == 'active'
      if ends_at.present? && starts_at.present?
        unless ends_at >= starts_at
          restaurant.errors.add(:base, "The end of your delivery hours must come after the corresponding delivery start time")
        end
      else
        restaurant.errors.add(:base, "You must provide both a start and end time for your delivery hours")
      end
    end

    if self.new_record?
      if restaurant.restaurant_availabilities.where(day_of_week: day_of_week).count != 0
        restaurant.errors.add(:base, "There is already an availability set for this day of the week. Please choose another day")
      elsif status == 'inactive'
        self.destroy
      end
    end

    return self.errors.count == 0
  end

  def update_validations
    create_validations
  end

  def starts_at(local = false)
    return nil if !read_attribute(:starts_at)
    if local
      timezone = restaurant.timezone || Time.zone.name
      converted_time = (starts_at.on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone)
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:starts_at)
    end
  end

  def ends_at(local = false)
    return nil if !read_attribute(:ends_at)
    if local
      timezone = restaurant.timezone || Time.zone.name
      converted_time = (ends_at.on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone)
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:ends_at)
    end
  end

  def day
    day_name = RestaurantAvailability.dows.select { |day, number| number == day_of_week }.keys[0]
    return day_name.camelcase
  end

  def self.day_of_week_non_iso(day)
    return 7 if day == "sunday"

    self.dows[day]
  end

  def self.by_dow
    order({day_of_week: :asc})
  end

  def starts_at_local
    starts_at(true)
  end

  def ends_at_local
    ends_at(true)
  end

  def starts_at_hour
    time = Tod::TimeOfDay.parse "#{starts_at_local}"
    "#{time.strftime('%l:%M %p')}"
  end

  def ends_at_hour
    time = Tod::TimeOfDay.parse "#{ends_at_local}"
    "#{time.strftime('%l:%M %p')}"
  end
end
