class UserDevice < ApplicationRecord
  include LunchproRecord

  belongs_to :user


end
