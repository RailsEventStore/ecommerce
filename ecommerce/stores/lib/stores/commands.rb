module Stores
  class RegisterStore < Infra::Command
    attribute :store_id, Infra::Types::UUID
  end

  class NameStore < Infra::Command
    attribute :store_id, Infra::Types::UUID
    attribute :name, Infra::Types.Instance(StoreName)
  end

  class RegisterProduct < Infra::Command
    attribute :store_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class RegisterCustomer < Infra::Command
    attribute :store_id, Infra::Types::UUID
    attribute :customer_id, Infra::Types::UUID
  end

  class RegisterOffer < Infra::Command
    attribute :store_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
  end

  class RegisterTimePromotion < Infra::Command
    attribute :store_id, Infra::Types::UUID
    attribute :time_promotion_id, Infra::Types::UUID
  end

  class RegisterCoupon < Infra::Command
    attribute :store_id, Infra::Types::UUID
    attribute :coupon_id, Infra::Types::UUID
  end
end
