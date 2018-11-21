class AddBudgetAndNotesToOfficesSalesRep < ActiveRecord::Migration[5.1]
  def change
    add_column :offices_sales_reps, :per_person_budget, :integer
    add_column :offices_sales_reps, :notes, :text
  end
end
