module Ordering
  class SubmitOrder < Command
    attribute :order_id, Types::UUID
    attribute :customer_id, Types::Coercible::Integer

    alias :aggregate_id :order_id
  end
end
