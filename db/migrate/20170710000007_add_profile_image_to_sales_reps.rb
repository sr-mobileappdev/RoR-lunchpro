class AddProfileImageToSalesReps < ActiveRecord::Migration[5.1]
  def change
    add_column :sales_reps, :profile_image, :string
  end
end
