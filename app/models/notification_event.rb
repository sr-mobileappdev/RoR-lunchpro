class NotificationEvent < ApplicationRecord
  include LunchproRecord

  has_many :notification_event_recipients, -> { where.not(status: ["deleted", "archived"]) }

  def notices
    @notices ||= Views::Notices.for_notification_event(self).all
  end

  def can_send_tests?
    if ['100'].include?(self.category_cid)
      return false
    else
      return true
    end
  end


  def self.__columns
    cols = {category_cid: 'Category ID', status__light: 'Status'}
    hidden_cols = []
    columns = self.__default_columns.merge(cols).except(*hidden_cols)
  end

end
