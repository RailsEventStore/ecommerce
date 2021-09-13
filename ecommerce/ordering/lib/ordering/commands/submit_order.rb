module Ordering
  class SubmitOrder < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :customer_id, Infra::Types::UUID

    alias :aggregate_id :order_id
  end
end
