module CouponDiscounts
  class RegisterCoupon < Infra::Command
    attribute :coupon_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    attribute :code, Infra::Types::String
    attribute :discount, Infra::Types::PercentageDiscount
    alias aggregate_id coupon_id
  end
end
