require_relative 'test_helper'
module Stores
  class CouponRegistrationTest < Test
    cover "Stores*"

    def test_coupon_should_get_registered
      store_id = SecureRandom.uuid
      coupon_id = SecureRandom.uuid
      assert register_coupon(store_id, coupon_id)
    end

    def test_should_publish_event
      store_id = SecureRandom.uuid
      coupon_id = SecureRandom.uuid
      coupon_registered = Stores::CouponRegistered.new(data: { store_id: store_id, coupon_id: coupon_id })
      assert_events("Stores::Store$#{store_id}", coupon_registered) do
        register_coupon(store_id, coupon_id)
      end
    end

    private

    def register_coupon(store_id, coupon_id)
      run_command(RegisterCoupon.new(store_id: store_id, coupon_id: coupon_id))
    end
  end
end
