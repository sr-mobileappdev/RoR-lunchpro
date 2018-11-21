class AddYearToHolidayExclusions < ActiveRecord::Migration[5.1]
  def change
    add_column :holiday_exclusions, :year, :integer
  end
end
