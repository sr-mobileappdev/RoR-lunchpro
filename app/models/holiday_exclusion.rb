class HolidayExclusion < ApplicationRecord
  include LunchproRecord
	has_and_belongs_to_many :offices

  def timeframe
    if starts_on != ends_on
      "#{starts_on} - #{ends_on}"
    else
      "#{starts_on}"
    end
  end

end
