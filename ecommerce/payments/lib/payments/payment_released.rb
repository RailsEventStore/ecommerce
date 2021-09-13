module Payments
  class PaymentReleased < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
