class OfficesSalesRep < ApplicationRecord
	# Budget per person is always pre-tax and pre-tip
  include LunchproRecord

  belongs_to :office
  belongs_to :sales_rep
  belongs_to :created_by, class_name: 'User'

	validates_presence_of :office, :sales_rep


  enum listed_type: {none: 0, blacklist: 1, standby: 2}, _prefix: true

  after_save :check_blacklist


  private

  def check_blacklist

  end

end