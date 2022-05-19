
require "test_helper"

class CouponsTest < InMemoryRESIntegrationTestCase
  def test_list_coupons
    run_command(
      CouponDiscounts::RegisterCoupon.new(
        coupon_id: SecureRandom.uuid,
        name: "Coupon Number Uno",
        code: "enterme",
        discount: "0.01"
      )
    )

    get "/coupons"
    assert_response :success
    assert_select("td", "Coupon Number Uno")
    assert_select("td", "enterme")
    assert_select("td", "0.01")
  end

  def test_creation
    post "/coupons", params: {
      coupon_id: SecureRandom.uuid,
      name: "Coupon Number Two",
      code: "fair_price",
      discount: "6.69"
    }
    follow_redirect!
    assert_response :success
    assert_select("p", "Coupon was successfully created")
    assert_select("td", "Coupon Number Two")
    assert_select("td", "fair_price")
    assert_select("td", "6.69")
  end
end
