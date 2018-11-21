class AddStatusToHolidayExclusions < ActiveRecord::Migration[5.1]
  def change
    add_column :holiday_exclusions, :status, :integer, default: 1
    add_column :cuisines, :status, :integer, default: 1
    add_column :diet_restrictions, :status, :integer, default: 1
  end
end
