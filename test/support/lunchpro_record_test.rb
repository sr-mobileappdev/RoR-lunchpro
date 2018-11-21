module LunchproRecordTest
  extend ActiveSupport::Concern

  included do
    test "should have active status enum" do
      u = @object
      assert_respond_to(u, :active?)
    end

    test "should have deleted status enum" do
      u = @object
      assert_respond_to(u, :deleted?)
    end
  end
end

