require "test_helper"

module Coupons
  class RegisterCouponTest < InMemoryTestCase
    cover "Coupons*"

    def test_coupon_registered_with_all_attributes
      event_store.publish(coupon_created)

      coupon = Coupon.find_by(uid: coupon_id)
      assert_equal(coupon_id, coupon.uid)
      assert_equal("Test Coupon", coupon.name)
      assert_equal("TEST123", coupon.code)
      assert_equal(BigDecimal("10.00"), coupon.discount)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def coupon_id
      @coupon_id ||= SecureRandom.uuid
    end

    def coupon_created
      Pricing::CouponRegistered.new(
        data: {
          coupon_id: coupon_id,
          name: "Test Coupon",
          code: "TEST123",
          discount: "10.00"
        }
      )
    end
  end
end
