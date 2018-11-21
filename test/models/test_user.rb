require 'test_helper'

class TestUser < ActiveSupport::TestCase
  include LunchproRecordTest

  def setup
    @user = @object = users(:active)
  end

  test "can belong to admin space" do
    @user.space_admin!
    assert @user.space_admin?
  end

  test "can belong to rep space" do
    @user.space_sales_rep!
    assert @user.space_sales_rep?
  end

  test "can belong to office space" do # Damn, it feels good to be a gangsta
    @user.space_office!
    assert @user.space_office?
  end

  test "can belong to restaurant space" do
    @user.space_restaurant!
    assert @user.space_restaurant?
  end

  test "can be validated" do
    admin_user = users(:admin)
    @user.validate!(admin_user)
    assert(@user.validated_at != nil)
    assert(@user.validated_by != nil)
    assert(@user.validated_by == admin_user)
  end

end
