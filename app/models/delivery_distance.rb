class DeliveryDistance < ApplicationRecord
	belongs_to :restaurant
	validates_presence_of :restaurant

	validate :create_validations, on: :create
	validate :update_validations, on: :update

	def create_validations
		unless radius
			self.radius = 10
		end
	end

	def update_validations
		if advanced_radius?
			unless self.validate_direction_values
				restaurant.errors.add(:base, "A value between 1 and 100 must be entered for each cardinal direction")
				self.errors.add(:base, "A value must be entered for each direction when using cardinal directions")
			end
		end

		unless radius != nil && radius >= 1 && radius <= 100
			restaurant.errors.add(:base, "A delivery radius with a value between 1 and 100 miles must be entered")
			self.errors.add(:base, "A delivery radius with a value between 1 and 100 miles must be entered")
		end
	end # if using complex radius, a value must be entered for each cardinal direction

	def advanced_radius?
		if use_complex == true
			return true
		else
			return false
		end
	end

  def display_radius
    return "" unless radius
    if use_complex
      self
    else
      "#{radius} Miles"
    end
  end

	def directions
		return [north, south, east, west, north_east, south_east, south_west, north_west]
	end

	def validate_direction_values
		self.directions.each do |dir|
			if dir.present?
				if dir >= 1 && dir <= 100
					return true
				end
			else
				return false
			end
		end
	end

end
