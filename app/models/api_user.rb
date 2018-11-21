class ApiUser < ApplicationRecord
  belongs_to :enabled_by_user, class_name: 'User'
  belongs_to :disabled_by_user, class_name: 'User'

  API_TOKEN_LENGTH = 16
  before_create :generate_token

  def generate_token
    self.api_key = SecureRandom.base64(API_TOKEN_LENGTH)
  end

  def self.generate!(name, creating_user)
    return false unless name.present? && creating_user
    ApiUser.create!(name: name, is_enabled: true, enabled_by_user_id: creating_user.id)
  end

  def touch!
    self.update_attributes(last_accessed_at: Time.now)
  end
end
