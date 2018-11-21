class AddQueuedAtToNotification < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :queued_at, :datetime
    add_column :notifications, :delay_minutes, :integer, default: 0
  end
end
