class DietRestrictionsOffice < ApplicationRecord
  attr_accessor :temp_restriction_id #will be used in edit/new form for office to track diet restrictions
  
	belongs_to :office
	belongs_to :diet_restriction
	validates_presence_of :office
  attr_accessor :_destroy

  def set_staff_count(count)
    @staff_count = count
  end

  def staff_count
    read_attribute(:staff_count) || 0
  end

end
