class DrugsSalesRep < ApplicationRecord
	include LunchproRecord

  belongs_to :sales_rep
  belongs_to :drug
end
