class ConvertLocationNamesToFull < ActiveRecord::Migration[5.1]
  def change
    unless column_exists? :restaurants, :latitude
      remove_column :restaurants, :lat
      add_column :restaurants, :latitude, :float
    end
    unless column_exists? :restaurants, :longitude
      remove_column :restaurants, :lon
      add_column :restaurants, :longitude, :float
    end

    unless column_exists? :offices, :latitude
      remove_column :offices, :lat
      add_column :offices, :latitude, :float
    end
    unless column_exists? :offices, :longitude
      remove_column :offices, :lon
      add_column :offices, :longitude, :float
    end
  end
end
