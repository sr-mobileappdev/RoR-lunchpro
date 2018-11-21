class CreateHolidayExclusions < ActiveRecord::Migration[5.1]
  def change
    create_table :holiday_exclusions do |t|
      t.string :name
      t.date :starts_on
      t.date :ends_on

      t.timestamps
    end
  end
end
