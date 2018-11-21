class Company < ApplicationRecord
  include LunchproRecord
	has_many :users
  has_many :sales_reps

  # -- Validates
  validate :create_validations, :on => :create
  validate :update_validations, :on => :update

  def create_validations
    unless name.present?
      self.errors.add(:base, "A name must be provided for the company")
    end
  end

  def update_validations
    unless name.present?
      self.errors.add(:base, "A name must be provided for the company")
    end
  end

  def active_companies

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
