module Stores

  class StoreRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
  end

  class StoreNamed < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end

  class ProductRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class CustomerRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :customer_id, Infra::Types::UUID
  end

  class OfferRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
  end

  class TimePromotionRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :time_promotion_id, Infra::Types::UUID
  end

  class CouponRegistered < Infra::Event
    attribute :store_id, Infra::Types::UUID
    attribute :coupon_id, Infra::Types::UUID
  end

end
