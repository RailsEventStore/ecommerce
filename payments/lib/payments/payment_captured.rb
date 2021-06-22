module Payments
  class PaymentCaptured < Event
    attribute :order_id,       Types::UUID
  end
end
