class UserAccessToken < ApplicationRecord
  include LunchproRecord
  belongs_to :user

  API_TOKEN_LENGTH = 16

  def self.generate!(user)
    UserAccessToken.create!(user_id: user.id, access_token: SecureRandom.base64(API_TOKEN_LENGTH), status: 'active', message: nil, last_accessed_at: Time.now)
  end

  def touch!(ip_address = nil)
    self.update_attribtes(last_accessed_at: Time.now, last_accessed_ip: ip_address)
  end

end
