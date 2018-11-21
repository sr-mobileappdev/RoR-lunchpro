class CreateProviderAvailabilities < ActiveRecord::Migration[5.1]
  def change
    create_table :provider_availabilities do |t|
      t.references :provider
      t.integer :dow
      t.timestamp :starts_at
      t.timestamp :ends_at

      t.timestamps
    end
  end
end
