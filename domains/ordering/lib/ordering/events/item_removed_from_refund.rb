module Ordering
  class ItemRemovedFromRefund < Infra::Event
    attribute :refund_id,  Infra::Types::UUID
    attribute :order_id,   Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
  end
end
