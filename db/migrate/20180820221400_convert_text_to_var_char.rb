class ConvertTextToVarChar < ActiveRecord::Migration[5.1]
  def change
  	change_column :appointments, :rep_notes, :string
  	change_column :appointments, :office_notes, :string
  	change_column :appointments, :delivery_notes, :string
  	change_column :appointments, :bring_food_notes, :string
  	change_column :diet_restrictions, :description, :string
  	change_column :line_items, :notes, :string
  	change_column :lunch_packs, :description, :string
  	change_column :menu_item_images, :caption, :string
  	change_column :menu_sub_items, :description, :string
  	change_column :notification_event_recipients, :content, :string
  	change_column :notification_event_recipients, :sms_content, :string
  	change_column :notification_event_recipients, :email_content, :string
  	change_column :notifications, :web_summary, :string
  	change_column :offices, :food_preferences, :string
  	change_column :offices, :delivery_instructions, :string
  	change_column :offices_sales_reps, :notes, :string
  	change_column :offices_sales_reps, :office_notes, :string
  	change_column :order_reviews, :comment, :string
  	change_column :orders, :rep_notes, :string
  	change_column :orders, :restaurant_notes, :string
  	change_column :restaurant_transactions, :notes, :string
  	change_column :restaurants, :description, :string
  	change_column :orders, :restaurant_notes, :string
  	change_column :sample_requests, :note, :string
  end
end
