class CreateMenuTypes < ActiveRecord::Migration[5.1]
  def change
    create_table :menu_types do |t|
      t.string :name
      t.time :start_time
      t.time :end_time

      t.timestamps
    end
  end
end
