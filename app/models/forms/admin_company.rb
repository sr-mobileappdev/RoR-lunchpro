class Forms::AdminCompany < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :company

  def initialize(user, params = {}, existing_company = nil)
    @current_user = user
    @params = params
    @errors = []

    @company = existing_company
  end

  def valid?

    raise "Missing required parameters (:company)" unless @params[:company]

    # Validate office
    @company ||= Company.new(status: 'active')
    @company.assign_attributes(@params[:company])


    unless @company.valid?
      @errors += @company.errors.full_messages
    end

    return (@errors.count == 0)
  end

  def save
    if valid? && persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @company.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
