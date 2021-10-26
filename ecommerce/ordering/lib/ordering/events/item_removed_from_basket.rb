module Ordering
  class ItemRemovedFromBasket < Infra::Event
    attribute :order_id,   Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end
end