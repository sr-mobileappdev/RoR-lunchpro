class CreateOfficePocs < ActiveRecord::Migration[5.1]
  def change
    create_table :office_pocs do |t|
      t.references :office, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :phone
      t.string :email

      t.timestamps
    end
  end
end
