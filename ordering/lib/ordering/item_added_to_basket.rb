module Ordering
  class ItemAddedToBasket < Event
    attribute :order_id,   Types::UUID
    attribute :product_id, Types::ID
  end
end