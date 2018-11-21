require "test_helper"

class OfficeReferralTest < ActiveSupport::TestCase
  def office_referral
    @office_referral ||= OfficeReferral.new
  end

  def test_valid
    assert office_referral.valid?
  end
end
