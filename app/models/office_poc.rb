class OfficePoc < ApplicationRecord
  include LunchproRecord

	# Point of Contact
	belongs_to :office
	validates_presence_of :office

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update
 
  before_create :set_default

  def set_default
    if self.primary.nil?
      self.primary = false
    end
  end

  def create_validations
    if status == 'deleted' || status == 'inactive' || _destroy
      return
    end

    #unless email.present? || phone.present?
      #self.errors.add(:base, "An Email Address or a Phone Number is required.")
    #end

    if email.present?
      self.errors.add(:base, "Email is Invalid") if !Constants::EMAIL_REGEXP.match(email).present?
    end

    unless first_name.present?
      self.errors.add(:base, "First name is required")
    end

    unless last_name.present?
      self.errors.add(:base, "Last name is required")
    end

    if phone.present? && (Office.select{|office| office.id != office_id && office.active? && office.phone.present? && office.phone.gsub(/\D/, '') == phone.gsub(/\D/, '')}.any? || 
      OfficePoc.select{|poc| poc.active? && poc.office_id != office_id && poc.office && poc.office.active? &&
      poc.phone.present? && poc.phone.gsub(/\D/, '') == phone.gsub(/\D/, '')}.any?)
      self.errors.add(:base, "That Phone Number is already in use by another Office.")
    end

    if primary.present? && primary && office.office_pocs.active.where(:primary => true).where.not(:id => id).count > 0
      self.errors.add(:base, "A primary POC has already been set for this office.")
    end
    return self.errors.count == 0
  end

  def update_validations
    if status == 'deleted' || status == 'inactive' || _destroy
      return
    end

    #unless email.present? || phone.present?
      #self.errors.add(:base, "An Email Address or a Phone Number is required.")
    #end

    if email.present?
      self.errors.add(:base, "Email is Invalid") if !Constants::EMAIL_REGEXP.match(email).present?
    end

    unless first_name.present?
      self.errors.add(:base, "First name is required")
    end

    unless last_name.present?
      self.errors.add(:base, "Last name is required")
    end

    #if poc is being deleted, don't validate phone number
    #check against office pocs whose office is active
    if phone.present? && (Office.select{|office| office.id != office_id && office.active? && office.phone.present? && office.phone.gsub(/\D/, '') == phone.gsub(/\D/, '')}.any? || 
      OfficePoc.select{|poc| poc.active? && poc.office_id != office_id && poc.office.active? && 
      poc.phone.present? && poc.phone.gsub(/\D/, '') == phone.gsub(/\D/, '')}.any?)
      self.errors.add(:base, "That Phone Number is already in use by another Office.")
    end
    if primary.present? && primary && office.office_pocs.active.where(:primary => true).where.not(:id => id).count > 0
      self.errors.add(:base, "A primary POC has already been set for this office.")
    end
  end


  def display_name
    (first_name && last_name) ? "#{first_name} #{last_name}" : email
  end

  def self.__columns
    cols = {display_name: 'Name'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
