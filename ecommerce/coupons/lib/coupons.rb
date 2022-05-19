require "infra"
require_relative "coupons/commands/register_coupon"
require_relative "coupons/events/coupon_registered"
require_relative "coupons/services/on_coupon_register"
require_relative "coupons/coupon" #aggregate root

module Coupons
  class Configuration

    def call(cqrs)
      cqrs.register_command(RegisterCoupon, OnCouponRegister.new(cqrs.event_store), CouponRegistered)
    end
  end
end

