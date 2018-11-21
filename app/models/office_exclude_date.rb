class OfficeExcludeDate < ApplicationRecord
	belongs_to :office
	validates_presence_of :office

  validate :create_validations, :on => :create
  validate :update_validations, :on => :update


  def create_validations
    if ends_at.present? && starts_at.present?
      unless ends_at >= starts_at
        office.errors.add(:base, "End date must be after start date.")
      end
      unless ends_at >= Time.now && starts_at >= Time.now
        office.errors.add(:base, "Start and End date cannot be in the past.")
      end

      if office.appointments.where(appointment_on: starts_at.to_date..ends_at.to_date, status: 'active', excluded: [nil, false]).exists?
        office.errors.add(:base, "You cannot exclude a date where an active appointment is set.")
      end
    else
      office.errors.add(:base, "You must provide both start and end dates.")
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
  
  def serializable_hash(options)
  		if !options.present?
  			options = Hash.new()
  		end	
		if options[:methods].present?
			options[:methods] << "starts_at_date"
			options[:methods] << "ends_at_date"
		else
			options[:methods] = ["starts_at_date","ends_at_date"]
		end
		super
	end

end
