class SalesRepEmail < ApplicationRecord
	# Schema Notes:
		# Some notifications, such as for rewards may go to a unique email address

	include LunchproRecord

  belongs_to :sales_rep

	enum email_type: {personal: 1, business: 2} # FIXME: flesh this out
  enum notification_preference: {notify_no: 1, notify_yes: 2}

	# NOTE: notification_preference currently an integer
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    if !email_address.present?
      self.errors.add(:base, "A #{email_name} Email Address is required.")
      sales_rep.errors.add(:base, "A #{email_name} Email Address is required.")
    end
    if email_address.present?
        sales_rep.errors.add(:base, email_name + " Email is Invalid") if !Constants::EMAIL_REGEXP.match(email_address).present?
        self.errors.add(:base, email_name + " Email is Invalid") if !Constants::EMAIL_REGEXP.match(email_address).present?   
      if new_record?
      	if SalesRepEmail.where(:status => 1, :email_type => email_type).where('lower(email_address) = ?', email_address).any?
      		sales_rep.errors.add(:base, email_name + " Email is not unique")
      		self.errors.add(:base, email_name + " Email is not unique")
      	end
      else
      	if SalesRepEmail.where(:status => 1, :email_type => email_type).where('lower(email_address) = ? AND id != ?', email_address, id).any?
      		sales_rep.errors.add(:base, email_name + " Email is not unique")
      		self.errors.add(:base, email_name + " Email is not unique")
      	end
      end
    end
    return self.errors.count == 0
  end

  def update_validations
    create_validations
  end

  def notify__flag
    notify_yes?
  end

  def email_name
    return "Business" if email_type == 'business'
    "Rewards" 
  end



  def self.__columns
    cols = {email_address: 'Email', email_type: 'Type', notify__flag: 'Notify?'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end
end
