class SalesRepPhone < ApplicationRecord
	include LunchproRecord

  belongs_to :sales_rep

	enum phone_type: {personal: 1, business: 2} # FIXME: flesh this out
  enum notification_preference: {notify_no: 1, notify_yes: 2}

  before_save :format_phone
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    if phone_type == 'business' && !phone_number.present?
      sales_rep.errors.add(:base, "A Business Phone Number is required.")
      self.errors.add(:base, "A Business Phone Number is required.")
    end

	if new_record? && phone_number
    	if SalesRepPhone.select{ |srp| srp.active? && srp.phone_type == phone_type && srp.phone_number && srp.phone_number.gsub(/\D/, '') == phone_number.gsub(/\D/, '') && srp.id != id }.any?
    		sales_rep.errors.add(:base, phone_type.humanize + " Phone number is not unique")
    		self.errors.add(:base, phone_type.humanize + " Phone number is not unique")
    	end
    elsif !new_record? && phone_number
    	if SalesRepPhone.select{ |srp| srp.active? && srp.phone_type == phone_type && srp.phone_number && srp.phone_number.gsub(/\D/, '') == phone_number.gsub(/\D/, '') && srp.id != id }.any?
    		sales_rep.errors.add(:base, phone_type.humanize + " Phone number is not unique")
    		self.errors.add(:base, phone_type.humanize + " Phone number is not unique")
    	end
    end
    
    return self.errors.count == 0
  end

  def update_validations
    create_validations
  end
  def format_phone
    if self.phone_number.present?
      write_attribute(:phone_number, self.phone_number.gsub(/\D/, ''))
    end
  end

  def notify__flag
    notify_yes?
  end

  def self.__columns
    cols = {phone_number: 'Phone Number', phone_type: 'Type', notify__flag: 'Notify?'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
