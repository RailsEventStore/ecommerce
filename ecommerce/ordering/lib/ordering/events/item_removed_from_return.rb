module Ordering
  class ItemRemovedFromReturn < Infra::Event
    attribute :return_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end

  ItemRemovedFromRefund = ItemRemovedFromReturn
end
