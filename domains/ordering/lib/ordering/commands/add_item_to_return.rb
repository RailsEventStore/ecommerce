module Ordering
  class AddItemToReturn < Infra::Command
    attribute :return_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID

    alias aggregate_id return_id
  end

  AddItemToRefund = AddItemToReturn
end
