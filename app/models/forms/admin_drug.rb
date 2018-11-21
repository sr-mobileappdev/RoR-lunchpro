class Forms::AdminDrug < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :drug

  def initialize(user, params = {}, existing_drug = nil)
    @current_user = user
    @params = params
    @errors = []

    @drug = existing_drug
  end

  def valid?

    raise "Missing required parameters (:drug)" unless @params[:drug]

    # Validate office
    @drug ||= Drug.new(status: 'active')
    @drug.assign_attributes(@params[:drug])


    unless @drug.valid?
      @errors += @drug.errors.full_messages
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
      if @drug.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
