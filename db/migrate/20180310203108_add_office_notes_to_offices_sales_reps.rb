class AddOfficeNotesToOfficesSalesReps < ActiveRecord::Migration[5.1]
  def change
    add_column :offices_sales_reps, :office_notes, :text
  end
end
