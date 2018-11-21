class CreateOfficeExcludeDates < ActiveRecord::Migration[5.1]
  def change
    create_table :office_exclude_dates do |t|
      t.references :office
      t.timestamp :starts_at
      t.timestamp :ends_at

      t.timestamps
    end
  end
end
