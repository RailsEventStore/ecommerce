module Ordering
  class DraftRefundCreated < Infra::Event
    attribute :refund_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
    attribute :refundable_products, Infra::Types::Array.of(
      Infra::Types::Hash.schema(
        product_id: Infra::Types::UUID,
        quantity: Infra::Types::Integer
      )
    )
  end
end
