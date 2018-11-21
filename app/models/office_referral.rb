class OfficeReferral < ApplicationRecord
  belongs_to :office, optional: true

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update
  
  def create_validations
    unless name.present?
      self.errors.add(:base, "An office name must be provided for a referral.")
    end

    unless email.present? || phone.present?
      self.errors.add(:base, "Am Email Address or a Phone Number is required.")
    end

    if name.present?
      self.errors.add(:base, "An Office with this name already exists!") if Office.where(:name => name, :status => 'active').exists?
    end

    if email.present?
      self.errors.add(:base, "Email is Invalid") if !Constants::EMAIL_REGEXP.match(email).present?
      self.errors.add(:base, "An Office associated with this Email Address already exists!") if OfficePoc.where(:email => email, :status => 'active').exists?
    end
    
    if phone.present?
      if (Office.select{|office| office.active? && office.phone.present? && office.phone.gsub(/\D/, '') == phone.gsub(/\D/, '')}.any? ||
          OfficePoc.select{|poc| poc.active? && poc.phone.present? && poc.phone.gsub(/\D/, '') == phone.gsub(/\D/, '')}.any?)
        self.errors.add(:base, "An Office associated with this Phone Number already exists!") 
      end
    end
  end

  def update_validations
  end

end
