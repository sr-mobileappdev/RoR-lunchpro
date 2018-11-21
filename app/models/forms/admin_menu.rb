class Forms::AdminMenu < Forms::Form
  attr_writer :params
  attr_writer :current_user
  attr_reader :errors

  attr_reader :menu

  def initialize(user, params = {}, existing_menu = nil)
    @current_user = user
    @params = params
    @errors = []

    @menu = existing_menu
  end

  def valid?

    raise "Missing required parameters (:menu)" unless @params[:menu]

    # Validate office
    @menu ||= Menu.new()
    @menu.assign_attributes(@params[:menu])
 
    unless @menu.valid?
      @errors += @menu.errors.full_messages
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
      if @menu.save
        return true
      else
        raise ActiveRecord::Rollback
      end
    end
    false
  end
end
