class RestaurantPoc < ApplicationRecord
  include LunchproRecord
  attr_accessor :notification_recipient_type
  belongs_to :restaurant
  validates_presence_of :restaurant

  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    unless first_name.present?
      self.errors.add(:base, "First name is required")
    end

    unless last_name.present?
      self.errors.add(:base, "Last name is required")
    end

    unless email.present? || phone.present?
      self.errors.add(:base, "An Email Address or a Phone Number is required.")
    end

    if email.present?
      self.errors.add(:base, "Email is Invalid") if !Constants::EMAIL_REGEXP.match(email).present?
    end
  end

  def update_validations
    create_validations
  end

  def notification_recipient_type
    "restaurant"
  end
  
  def display_name
    (first_name && last_name) ? "#{first_name} #{last_name}" : email
  end

end
