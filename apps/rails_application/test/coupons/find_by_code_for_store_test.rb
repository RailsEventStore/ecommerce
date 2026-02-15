require "test_helper"

module Coupons
  class FindByCodeForStoreTest < InMemoryTestCase
    cover "Coupons*"

    def configure(event_store, _command_bus)
      Coupons::Configuration.new.call(event_store)
    end

    def test_finds_coupon_by_code_for_store
      event_store.publish(coupon_created)
      event_store.publish(coupon_registered_in_store)

      coupon = Coupons.find_by_code_for_store("TEST123", store_id)

      assert_equal(coupon_id, coupon.uid)
      assert_equal("TEST123", coupon.code)
    end

    def test_finds_coupon_case_insensitively
      event_store.publish(coupon_created)
      event_store.publish(coupon_registered_in_store)

      coupon = Coupons.find_by_code_for_store("test123", store_id)

      assert_equal(coupon_id, coupon.uid)
    end

    def test_raises_when_coupon_not_found
      assert_raises(ActiveRecord::RecordNotFound) do
        Coupons.find_by_code_for_store("NONEXISTENT", store_id)
      end
    end

    def test_raises_when_coupon_belongs_to_different_store
      other_store_id = SecureRandom.uuid

      event_store.publish(coupon_created)
      event_store.publish(coupon_registered_in_store)

      assert_raises(ActiveRecord::RecordNotFound) do
        Coupons.find_by_code_for_store("TEST123", other_store_id)
      end
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def coupon_id
      @coupon_id ||= SecureRandom.uuid
    end

    def store_id
      @store_id ||= SecureRandom.uuid
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

    def coupon_registered_in_store
      Stores::CouponRegistered.new(data: { coupon_id: coupon_id, store_id: store_id })
    end
  end
end
