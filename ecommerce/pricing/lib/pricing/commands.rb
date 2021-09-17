module Pricing
  class AddItemToBasket < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID

    alias aggregate_id order_id
  end

  class RemoveItemFromBasket < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID

    alias aggregate_id order_id
  end

  class CalculateTotalValue < Infra::Command
    attribute :order_id, Infra::Types::UUID
    alias aggregate_id order_id
  end

  class SetPrice < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :price, Infra::Types::Price
  end

  class ItemAddedToBasket < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class ItemRemovedFromBasket < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  class SetPercentageDiscount < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :amount, Infra::Types::PercentageDiscount
  end
end
