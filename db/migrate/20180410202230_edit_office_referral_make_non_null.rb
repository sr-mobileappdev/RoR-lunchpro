class EditOfficeReferralMakeNonNull < ActiveRecord::Migration[5.1]
  def change
    change_column :office_referrals, :name, :string, :null => false
    change_column :office_referrals, :created_by_id, :integer, :null => false
  end
end
