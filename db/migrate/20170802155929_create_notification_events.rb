class CreateNotificationEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_events do |t|
      t.string :category_cid
      t.integer :status, default: 1
      t.string :internal_summary
      t.integer :activated_by_user
      t.datetime :activated_at
      t.integer :deactivated_by_user
      t.datetime :deactivated_at

      t.timestamps
    end
  end
end
