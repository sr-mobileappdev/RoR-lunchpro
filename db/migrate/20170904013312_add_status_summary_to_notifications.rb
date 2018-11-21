class AddStatusSummaryToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :status_summary, :jsonb
  end
end
