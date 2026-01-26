module Ordering
  class CreateDraftReturn < Infra::Command
    attribute :return_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID

    alias aggregate_id return_id
  end

  CreateDraftRefund = CreateDraftReturn
end
