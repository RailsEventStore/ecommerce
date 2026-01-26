module Inventory
  class Supply < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :quantity, Infra::Types::Coercible::Integer.constrained(gteq: 1)
  end
end
