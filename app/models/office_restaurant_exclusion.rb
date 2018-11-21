class OfficeRestaurantExclusion < ApplicationRecord
	belongs_to :office
	belongs_to :restaurant
	validates_presence_of :office, :restaurant
end
