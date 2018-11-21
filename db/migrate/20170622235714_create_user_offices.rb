class CreateUserOffices < ActiveRecord::Migration[5.1]
  def change
    create_table :user_offices do |t|
      t.integer :user_id
      t.integer :office_id
      t.integer :status

      t.timestamps
    end
  end
end
