class Cuisine < ApplicationRecord
  include LunchproRecord
	has_and_belongs_to_many :restaurants


  def self.for_restaurants(restaurant = nil)
    all.order(name: :asc)
  end
end
