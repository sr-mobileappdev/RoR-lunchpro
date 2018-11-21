class BankAccount < ApplicationRecord
	include LunchproRecord

	belongs_to :restaurant
  belongs_to :created_by, class_name: 'User'

	enum account_type: {checking: 1, savings: 2}

	validates_presence_of :restaurant, :routing_number, :account_number, :account_type, :bank_name

	validate :create_validations, on: :create
	validate :update_validations, on: :update


	def create_validations
		unless account_number.length >= 4 && account_number.length <= 17
			self.errors.add(:base, "Account number must be between 4 and 17 digits long")
		end

		unless account_number.scan(/\D/).empty?
			self.errors.add(:base, "Account number must contain only digits")
		end

		unless routing_number.length == 9 && routing_number.scan(/\D/).empty?
			self.errors.add(:base, "Routing number must be a nine-digit code")
		end

		unless account_type.present?
			account_type = 'checking'
		end

		return self.errors.count == 0
	end

	def update_validations
		create_validations
	end

  def display_name
		bank_name.upcase if bank_name
  end

	def display_account_type
		account_type.camelcase
	end

  def display_account_number
    #"XXXX-XXXX-#{account_number.last(4)}"
    account_number
  end

  def display_routing_number
  	routing_number
  end

  def self.__columns
    cols = {account_type: 'Account Type', display_location_single: 'Location', display_location: 'Location', private__flag: 'Is Private?'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
