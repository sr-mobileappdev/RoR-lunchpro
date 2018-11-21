require 'test_helper'

class TestSalesRep < ActiveSupport::TestCase
  include LunchproRecordTest

  def setup
    @sales_rep = @object = sales_reps(:active)
  end

  test "something" do

  end
end
