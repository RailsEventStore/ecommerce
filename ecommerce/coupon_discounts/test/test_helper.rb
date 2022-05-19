require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/coupon_discounts"

module CouponDiscounts
  class Test < Infra::InMemoryTest
    def before_setup
      super()
      Configuration.new.call(cqrs)
    end

    private

    def register_coupon(uid, name, code, discount)
      run_command(RegisterCoupon.new(coupon_id: uid, name: name, code: code, discount: discount))
    end

    def fake_name
      "Fake name"
    end
  end
end

