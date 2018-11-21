class CreateProviderExcludeDates < ActiveRecord::Migration[5.1]
  def change
    create_table :provider_exclude_dates do |t|
      t.references :provider
      t.timestamp :starts_at
      t.timestamp :ends_at

      t.timestamps
    end
  end
end
