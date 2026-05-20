module Ordering
  class CreateDraftReturn < Infra::Command
    attribute :return_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
    attribute :returnable_products, Infra::Types::Array.of(
      Infra::Types::Hash.schema(
        product_id: Infra::Types::UUID,
        quantity: Infra::Types::Integer
      )
    )

    alias aggregate_id return_id
  end

  CreateDraftRefund = CreateDraftReturn
end
