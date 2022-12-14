
require "test_helper"

class CouponsTest < InMemoryRESIntegrationTestCase
  def test_list_coupons
    register_coupon("Coupon Number Uno", "enterme", "0.01")

    get "/coupons"
    assert_response :success
    assert_select("td", "Coupon Number Uno")
    assert_select("td", "enterme")
    assert_select("td", "0.01")
  end

  def test_creation
    register_coupon("Coupon Number Two", "fair_price", "6.69")
    assert_response :success
    assert_select("p", "Coupon was successfully created")
    assert_select("td", "Coupon Number Two")
    assert_select("td", "fair_price")
    assert_select("td", "6.69")
  end

  private

  def register_coupon(name, code, discount)
    post "/coupons", params: {
      coupon_id: SecureRandom.uuid,
      name: name,
      code: code,
      discount: discount
    }
    Coupons::RegisterCoupon.drain

    follow_redirect!
  end
end
