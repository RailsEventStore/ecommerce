require "test_helper"

module Coupons
  class CouponsForStoreTest < InMemoryTestCase
    cover "Coupons*"

    def test_returns_coupons_for_store
      store_2_id = SecureRandom.uuid

      event_store.publish(coupon_created(coupon_1_id, "Coupon 1", "CODE1"))
      event_store.publish(coupon_created(coupon_2_id, "Coupon 2", "CODE2"))
      event_store.publish(coupon_created(coupon_3_id, "Coupon 3", "CODE3"))

      event_store.publish(coupon_registered_in_store(coupon_1_id, store_id))
      event_store.publish(coupon_registered_in_store(coupon_2_id, store_id))
      event_store.publish(coupon_registered_in_store(coupon_3_id, store_2_id))

      coupons = Coupons.coupons_for_store(store_id)

      assert_equal(2, coupons.count)
      assert_equal([coupon_1_id, coupon_2_id].sort, coupons.pluck(:uid).sort)
    end

    def test_returns_empty_for_store_with_no_coupons
      event_store.publish(coupon_created(coupon_1_id, "Coupon 1", "CODE1"))

      coupons = Coupons.coupons_for_store(store_id)

      assert_equal(0, coupons.count)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def coupon_1_id
      @coupon_1_id ||= SecureRandom.uuid
    end

    def coupon_2_id
      @coupon_2_id ||= SecureRandom.uuid
    end

    def coupon_3_id
      @coupon_3_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
    end

    def coupon_created(id, name, code)
      Pricing::CouponRegistered.new(
        data: {
          coupon_id: id,
          name: name,
          code: code,
          discount: "10.00"
        }
      )
    end

    def coupon_registered_in_store(coupon_id, store_id)
      Stores::CouponRegistered.new(data: { coupon_id: coupon_id, store_id: store_id })
    end
  end
end
