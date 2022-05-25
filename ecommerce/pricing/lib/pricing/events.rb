module Pricing
  class CouponRegistered < Infra::Event
    attribute :coupon_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    attribute :code, Infra::Types::String
    attribute :discount, Infra::Types::CouponDiscount
  end

  class PriceSet < Infra::Event
    attribute :product_id, Infra::Types::UUID
    attribute :price, Infra::Types::Price
  end

  class OrderTotalValueCalculated < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :discounted_amount, Infra::Types::Value
    attribute :total_amount, Infra::Types::Value
  end

  class PriceItemValueCalculated < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :quantity, Infra::Types::Quantity
    attribute :discounted_amount, Infra::Types::Value
    attribute :amount, Infra::Types::Value
  end

  class PercentageDiscountSet < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :amount, Infra::Types::Price
  end

  class PriceItemAdded < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class PriceItemRemoved < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class PercentageDiscountReset < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end

  class PercentageDiscountChanged < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :amount, Infra::Types::Price
  end
end
