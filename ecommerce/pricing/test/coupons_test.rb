require_relative "test_helper"

module Pricing
  class CouponsTest < Test
    cover "Pricing::Coupon*"

    def setup
      @uid = SecureRandom.uuid
      @code = fake_name.chars.shuffle.join
      @discount = 10
      @data = { coupon_id: @uid, name: fake_name, code: @code, discount: @discount }
    end

    def test_coupon_should_get_registered
      register_coupon(@uid, fake_name, @code, rand(1..20))
    end

    def test_should_not_allow_for_id_based_duplicates
      assert_raises(Pricing::Coupon::AlreadyRegistered) do
        register_coupon(@uid, fake_name, @code, @discount)
        register_coupon(@uid, fake_name, @code, @discount)
      end
    end

    def test_should_publish_event
      coupon_registered = CouponRegistered.new(data: @data)
      assert_events("Pricing::Coupon$#{@uid}", coupon_registered) do
        register_coupon(@uid, fake_name, @code, @discount)
      end
    end

    def test_100_is_ok
      register_coupon(@uid, fake_name, @code, 100)
    end

    def test_0_01_is_ok
      register_coupon(@uid, fake_name, @code, 0.01)
    end
  end
end
