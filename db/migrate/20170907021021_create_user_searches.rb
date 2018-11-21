class CreateUserSearches < ActiveRecord::Migration[5.1]
  def change
    create_table :user_searches do |t|
      t.integer :user_id
      t.integer :status, default: 1
      t.string :search_type
      t.string :search_model
      t.jsonb :conditions
      t.string :name
      t.datetime :saved_at

      t.timestamps
    end
  end
end
