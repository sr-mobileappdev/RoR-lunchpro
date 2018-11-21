class Forms::AdminOrder < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :order
  attr_reader :user

  def initialize(user, params = {})
    @current_user = user
    @params = params
    @errors = []
  end

  def valid?
    raise "Missing required parameters (:appointment)" unless @params[:order]

    # Validate Order
    @order = Order.new(@params[:appointment])

    unless @order.valid?
      @errors += @order.errors.full_messages
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
      if @order.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
