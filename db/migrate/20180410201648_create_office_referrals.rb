class CreateOfficeReferrals < ActiveRecord::Migration[5.1]
  def change
    create_table :office_referrals do |t|
      t.references :office
      t.string :name
      t.string :phone
      t.string :email
      t.integer :created_by_id

      t.timestamps
    end
  end
end
