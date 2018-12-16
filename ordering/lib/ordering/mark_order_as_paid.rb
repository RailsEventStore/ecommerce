module Ordering
  class MarkOrderAsPaid < Command
    attribute :order_id, Types::UUID
    attribute :transaction_id, Types::Coercible::String

    alias :aggregate_id :order_id
  end
end
