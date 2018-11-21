class CreateProviders < ActiveRecord::Migration[5.1]
  def change
    create_table :providers do |t|
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :specialty
      t.string :title

      t.timestamps
    end
  end
end
