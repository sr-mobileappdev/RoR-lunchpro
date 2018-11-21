class RenamePartnerAvailabilitiesDowToDayOfWeek < ActiveRecord::Migration[5.1]
  def change
    rename_column :provider_availabilities, :dow, :day_of_week
    change_column :provider_availabilities, :starts_at, :time
    change_column :provider_availabilities, :ends_at, :time
    add_column :provider_availabilities, :status, :integer, default: 1
    add_column :provider_availabilities, :created_by_id, :integer
  end
end
