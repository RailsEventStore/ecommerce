module Ordering
  class CreateDraftRefund < Infra::Command
    attribute :refund_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID

    alias aggregate_id refund_id
  end
end
