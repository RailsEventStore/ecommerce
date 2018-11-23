module Ordering
  class AddItemToBasket < Command
    attribute :order_id, Types::UUID
    attribute :product_id, Types::Coercible::Integer

    alias :aggregate_id :order_id
  end
end