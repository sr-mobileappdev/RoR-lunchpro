class AddRelatedObjectsToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :related_objects, :jsonb
  end
end
