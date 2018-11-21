class RestaurantExcludeDate < ApplicationRecord
	belongs_to :restaurant
	validates_presence_of :restaurant

	validate :create_validations, on: :create
	validate :update_validations, on: :update


	def create_validations
		if ends_at.present? && starts_at.present?
			unless ends_at >= starts_at
				restaurant.errors.add(:base, "End date must be after the start date.")
			end
			unless ends_at >= Time.now && starts_at >= Time.now
				restaurant.errors.add(:base, "Start and End date cannot be in the past.")
			end

			if restaurant.orders.where(status: 'active').exists?
				if restaurant.orders.select{|order| ['active'].include?(order.status) && (starts_at.to_date..ends_at.to_date).include?(order.appointment.appointment_on)}.any?
						restaurant.errors.add(:base, "You cannot exclude a date where an active order is set.")
						return
				end
			end
		else
			restaurant.errors.add(:base, "You must provide both start and end dates.")
		end
		return self.errors.count == 0
	end

	def update_validations
		create_validations
	end

end
