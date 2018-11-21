class CreatePayments < ActiveRecord::Migration[5.1]
  def change
    create_table :payments do |t|
      t.references :user
      t.string :stripe_identifier
      t.integer :last_four
      t.integer :cc_type
      t.date :expires_on
      t.integer :sort_order

      t.timestamps
    end
  end
end
