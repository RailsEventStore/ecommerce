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

  class TimePromotionCreated < Infra::Event
    attribute :time_promotion_id, Infra::Types::UUID
    attribute? :discount, Infra::Types::PercentageDiscount
    attribute? :start_time, Infra::Types::Time
    attribute? :end_time, Infra::Types::Time
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
    attribute :type, Infra::Types::String
    attribute :amount, Infra::Types::PercentageDiscount
    attribute :base_total_value, Infra::Types::Price
    attribute :total_value, Infra::Types::Price
  end

  class PriceItemAdded < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :base_price, Infra::Types::Price
    attribute :price, Infra::Types::Price
    attribute :base_total_value, Infra::Types::Price
    attribute :total_value, Infra::Types::Price
    attribute? :applied_promotion, Infra::Types::String
  end

  class PriceItemRemoved < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :base_price, Infra::Types::Price
    attribute :price, Infra::Types::Price
    attribute :base_total_value, Infra::Types::Price
    attribute :total_value, Infra::Types::Price
  end

  class PercentageDiscountRemoved < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :type, Infra::Types::String
    attribute :base_total_value, Infra::Types::Price
    attribute :total_value, Infra::Types::Price
  end

  class PercentageDiscountChanged < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :type, Infra::Types::String
    attribute :amount, Infra::Types::Price
    attribute :base_total_value, Infra::Types::Price
    attribute :total_value, Infra::Types::Price
  end

  class ProductMadeFreeForOrder < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class FreeProductRemovedFromOrder < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class CouponUsed < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :coupon_id, Infra::Types::UUID
    attribute :discount, Infra::Types::CouponDiscount
  end

  class OfferAccepted < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :order_lines, Infra::Types::Array do
      attribute :product_id, Infra::Types::UUID
      attribute :quantity, Infra::Types::Quantity
    end
  end

  class OfferRejected < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :reason, Infra::Types::String
    attribute? :unavailable_product_ids, Infra::Types::Array.of(Infra::Types::UUID)
  end

  class OfferExpired < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
