module Payments
  class PaymentCaptured < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
