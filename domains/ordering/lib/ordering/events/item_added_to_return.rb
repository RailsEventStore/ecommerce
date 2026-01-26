module Ordering
  class ItemAddedToReturn < Infra::Event
    attribute :return_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  ItemAddedToRefund = ItemAddedToReturn
end
