class AddWebSummaryToNotifications < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :web_summary, :text
  end
end
