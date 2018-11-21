class PaymentMethod < ApplicationRecord # ie. Payment Methods
	include LunchproRecord

  #aliasing for stripe columns
  alias_attribute :name, :cardholder_name
  alias_attribute :address_city, :city
  alias_attribute :address_state, :state
  alias_attribute :address_zip, :postal_code
  alias_attribute :exp_month, :expire_month
  alias_attribute :exp_year, :expire_year
	# Charge Rules:
		# Reserved funds on card: 12 hours prior
		# Funds taken: 3 hours after delivery

	belongs_to :user

	has_many :order_transactions
  has_many :orders

	validates_presence_of :user
	# validates_uniqueness_of :sort_order, scope: :user_id

	# these are the valid stripe "brands"
	enum cc_type: {unknown: 0, visa: 1, american_express: 2, mastercard: 3, discover: 4, jcb: 5, diners_club: 6}
  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update
  
  def create_validations

  end

  def update_validations
    if self.status_changed? && self.status_was == 'active' && self.status == 'inactive' && orders.select{|o| (o.active? || o.pending?) && 
      o.appointment.appointment_time(true) > Time.now.in_time_zone(o.appointment.office.timezone)}.any?

      self.errors.add(:base, "You cannot delete a payment method that will be used in upcoming orders.")

    end
  end

	def default
		user.payment_methods.active.order(:sort_order).first == self
	end#is_default?

	def stripe_customer
		user.stripe_customer
	end#stripe_customer
  
  def display_summary
    "#{display_name}"    
  end

  def card_number
    "xxxx - xxxx - xxxx - #{last_four}"
  end

  def short_display_name
    "ending in #{last_four}"
  end

  def display_name
    return "#{nickname} (ending in #{last_four})" if nickname.present?
    card_number
  end

	def expired?
		# cards typically expire on the last day of the 'expiration' month
	end


	def expires_on
		# cards typically expire on the last day of the 'expiration' month
	end

  def last_four
    read_attribute(:last_four).to_s.rjust(4, "0")
  end


	def self.stripe_object(stripe_identifier) # self so we only call Stripe when we need it.
		if stripe_identifier
			Stripe::Customer.retrieve(user.stripe_customer).sources.retrieve(stripe_identifier)
		end
	end


end # PaymentMethod
