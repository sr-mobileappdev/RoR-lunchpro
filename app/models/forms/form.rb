class Forms::Form
  attr_writer :params
  attr_reader :errors

  def trigger_notifications(category_cids, objects = [], options = {})
    Managers::NotificationManager.trigger_notifications(category_cids, objects, options) # @record = sales rep
  end

  def save
    if valid?
      persist!
      true
    else
      false
    end
  end

private

  def persist!
    true
  end
end
