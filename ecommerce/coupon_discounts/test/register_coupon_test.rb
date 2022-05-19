require_relative "test_helper"

module CouponDiscounts
  class RegistrationTest < Test
    cover "CouponDiscounts*"

    def test_coupon_should_get_registered
      uid = SecureRandom.uuid
      code = fake_name.chars.shuffle.join
      register_coupon(uid, fake_name, code, rand(1..20))
    end

    def test_should_not_allow_for_duplicates
      assert_raises(CouponDiscounts::Coupon::AlreadyRegistered) do
        code = fake_name.chars.shuffle.join
        discount = rand(1..20)
        register_coupon(SecureRandom.uuid, fake_name, code, discount)
        register_coupon(SecureRandom.uuid, fake_name, code, discount)
      end
    end

    def test_should_publish_event
      uid = SecureRandom.uuid
      code = fake_name.chars.shuffle.join
      discount = rand(1..20)
      data = { coupon_id: uid, name: fake_name, code: code, discount: discount }
      coupon_registered = CouponRegistered.new(data: data)
      assert_events("CouponDiscounts::Coupon$#{uid}", coupon_registered) do
        register_coupon(uid, fake_name, code, discount)
      end
    end
  end
end

