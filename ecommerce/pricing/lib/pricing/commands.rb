module Pricing
  class AddPriceItem < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID

    alias aggregate_id order_id
  end

  class RemovePriceItem < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID

    alias aggregate_id order_id
  end

  class CalculateTotalValue < Infra::Command
    attribute :order_id, Infra::Types::UUID
    alias aggregate_id order_id
  end

  class CalculateSubAmounts < Infra::Command
    attribute :order_id, Infra::Types::UUID
    alias aggregate_id order_id
  end

  class SetPrice < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :price, Infra::Types::Price
  end

  class SetFuturePrice < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :price, Infra::Types::Price
    attribute :valid_since, Infra::Types::Time
  end

  class SetPercentageDiscount < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :amount, Infra::Types::PercentageDiscount
    alias aggregate_id order_id
  end

  class ResetPercentageDiscount < Infra::Command
    attribute :order_id, Infra::Types::UUID
    alias aggregate_id order_id
  end

  class RegisterCoupon < Infra::Command
    attribute :coupon_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    attribute :code, Infra::Types::String
    attribute :discount, Infra::Types::CouponDiscount
    alias aggregate_id coupon_id
  end

  class CreateTimePromotion < Infra::Command
    attribute :time_promotion_id, Infra::Types::UUID.meta(omittable: true)
    attribute :discount, Infra::Types::PercentageDiscount
    attribute :start_time, Infra::Types::Time
    attribute :end_time, Infra::Types::Time
    attribute :label, Infra::Types::String
  end

  class ChangePercentageDiscount < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :amount, Infra::Types::PercentageDiscount
    alias aggregate_id order_id
  end

  class MakeProductFreeForOrder < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID

    alias aggregate_id order_id
  end

  class RemoveFreeProductFromOrder < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID

    alias aggregate_id order_id
  end
end
