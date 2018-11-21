class Forms::AdminBankAccount < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :bank_account

  def initialize(user, params = {}, existing = nil)
    @current_user = user
    @params = params
    @errors = []

    @bank_account = existing
  end

  def valid?

    raise "Missing required parameters (:menu)" unless @params[:bank_account]

    # Validate office
    @bank_account ||= BankAccount.new()
    @bank_account.assign_attributes(@params[:bank_account])

    unless @bank_account.valid?
      @errors += @bank_account.errors.full_messages
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
      if @bank_account.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
