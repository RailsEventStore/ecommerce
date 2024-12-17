module Ordering
  class DraftRefundCreated < Infra::Event
    attribute :refund_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
  end
end
