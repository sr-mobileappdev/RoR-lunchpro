class ProviderExcludeDate < ApplicationRecord
	belongs_to :provider
	validates_presence_of :provider

  validate :create_validations, :on => :create
  validate :update_validations, :on => :update


  def create_validations
    if ends_at.present? && starts_at.present?
      unless ends_at >= starts_at
        provider.errors.add(:base, "End date must be after start date.")
      end
      unless ends_at >= Time.now && starts_at >= Time.now
        provider.errors.add(:base, "Start and End date cannot be in the past.")
      end
    else
      provider.errors.add(:base, "You must provide both start and end dates.")
    end
    return self.errors.count == 0
  end

  def update_validations
    create_validations
  end
  
  def starts_at_date
  	return starts_at.strftime("%Y-%m-%d")
  end
  
  def ends_at_date
    return ends_at.strftime("%Y-%m-%d")
  end
end
