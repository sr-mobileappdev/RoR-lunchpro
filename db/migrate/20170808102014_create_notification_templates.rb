class CreateNotificationTemplates < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_templates do |t|
      t.string :template_type
      t.integer :status
      t.string :service
      t.string :key
      t.integer :version

      t.timestamps
    end
  end
end
