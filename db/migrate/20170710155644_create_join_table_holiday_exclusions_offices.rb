class CreateJoinTableHolidayExclusionsOffices < ActiveRecord::Migration[5.1]
  def change
    create_join_table :holiday_exclusions, :offices do |t|
      t.index [:holiday_exclusion_id, :office_id], name: :holiday_exclusions_offices_excl_id_and_office_id
      t.index [:office_id, :holiday_exclusion_id], name: :holiday_exclusions_offices_office_id_and_excl_id
    end
  end
end
