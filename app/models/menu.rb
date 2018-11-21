class Menu < ApplicationRecord
  include LunchproRecord

  serialize :start_time, Tod::TimeOfDay
  serialize :end_time, Tod::TimeOfDay

  belongs_to :restaurant
	has_and_belongs_to_many :menu_items, dependent: :destroy

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def self.draft
    inactive.where(published_at: nil)
  end

  def create_validations
    unless !name.empty?
      self.errors.add(:base, "A name must be provided for the menu")
    end

    unless start_time.present? && end_time.present?
      self.errors.add(:base, "A start and end time must be selected")
    end
  end

  def update_validations
    unless !name.empty?
      self.errors.add(:base, "A name must be provided for the menu")
    end
  end

  def start_time(local = false)
    #default pass back as utc
    #or use office timezone or local timezone and convert time to datetime object with offset of timezone
    if local
      timezone = self.restaurant.timezone || Time.zone.name
      converted_time = (Tod::TimeOfDay(start_time).on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone)
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:start_time)
    end
  end

  def end_time(local = false)
    #default pass back as utc
    #or use office timezone or local timezone and convert time to datetime object with offset of timezone
    if local
      timezone = self.restaurant.timezone || Time.zone.name
      converted_time = (Tod::TimeOfDay(end_time).on Date.current).asctime.in_time_zone("UTC").in_time_zone(timezone)
      Tod::TimeOfDay(converted_time.to_s(:time))
    else
      read_attribute(:end_time)
    end
  end

  def start_time=(time)
    if time.present?
      self[:start_time] = Managers::TimeManager.new(time, nil, nil, self.restaurant.timezone).time_converted_to_utc
    end
  end

  def end_time=(time)
    if time.present?
      self[:end_time] = Managers::TimeManager.new(time, nil, nil, self.restaurant.timezone).time_converted_to_utc
    end
  end

  def activate!
    self.published_at = Time.now
    self.status = "active"

    self.save
  end

  def add_item(item)
    menu_items << item
    self.save
  end

  def available_time
    if start_time && end_time
      start_at = start_time(true).strftime("%l:%M %P")
      end_at = end_time(true).strftime("%l:%M %P")
      "#{start_at} - #{end_at}"
    else
      ""
    end
  end

  def self.__columns
    cols = {available_time: 'Available'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
