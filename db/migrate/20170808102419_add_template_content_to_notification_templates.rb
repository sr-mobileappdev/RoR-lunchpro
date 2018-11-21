class AddTemplateContentToNotificationTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :notification_templates, :template_content, :jsonb
  end
end
