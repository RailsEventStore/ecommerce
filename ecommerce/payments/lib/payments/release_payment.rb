module Payments
  class ReleasePayment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end
