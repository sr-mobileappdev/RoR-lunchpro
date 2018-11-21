class ChangeStatusToIntForRestuarantAvailabilities < ActiveRecord::Migration[5.1]
  def change
    change_column_default :restaurant_availabilities, :status, nil
  end
end
