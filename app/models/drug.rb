class Drug < ApplicationRecord
  include LunchproRecord

	has_many :drugs_sales_reps
	has_many :sales_reps, through: :drugs_sales_reps

	has_many :sample_requests

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    unless brand.present?
      self.errors.add(:base, "A name must be provided for the drug.")
    end
    if brand.present?
    	if Drug.where("status = ? AND lower(brand) = ?", 1, brand.downcase).exists?
    		self.errors.add(:base, "A drug with this brand name already exists")
    	end 
    end
  end

  def update_validations
    unless brand.present?
      self.errors.add(:base, "A name must be provided for the drug.")
    end
  end

  # -- Search / Query Scoping
  def self.scope_params_for(scope_strings = [])
    params = {}

    scope_strings.each do |scope|
      case scope
        when "active"
          params["status"] = "active"
        when "inactive"
          params["status"] = "inactive"
      end
    end

    params
  end
  # --

end
