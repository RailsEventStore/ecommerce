module Inventory
  class Supply < Command
    attribute :product_id, Types::UUID
    attribute :quantity, Types::Coercible::Integer.constrained(gteq: 1)
  end
end