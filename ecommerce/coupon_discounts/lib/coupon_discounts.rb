require "infra"
require_relative "coupon_discounts/commands/register_coupon"
require_relative "coupon_discounts/events/coupon_registered"
require_relative "coupon_discounts/services/on_coupon_register"
require_relative "coupon_discounts/coupon" #aggregate root

module CouponDiscounts
  class Configuration

    def call(cqrs)
      cqrs.register_command(RegisterCoupon, OnCouponRegister.new(cqrs.event_store), CouponRegistered)
    end
  end
end

