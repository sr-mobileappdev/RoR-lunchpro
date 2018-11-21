class Forms::AdminOfficePoc < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :office_poc

  def initialize(user, params = {}, existing_office_poc = nil)
    @current_user = user
    @params = params
    @errors = []

    @office_poc = existing_office_poc
  end

  def valid?

    raise "Missing required parameters (:office_poc)" unless @params[:office_poc]

    # Validate Sales Rep
    @office_poc ||= OfficePoc.new()
    @office_poc.assign_attributes(@params[:office_poc])


    unless @office_poc.valid?
      @errors += @office_poc.errors.full_messages
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

  def save_and_invite
    if valid? && persist!
      true
    else
      false
    end
  end

private

  def persist!
    ActiveRecord::Base.transaction do
      if @office_poc.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
