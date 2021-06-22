module Payments
  class PaymentReleased < Event
    attribute :order_id,       Types::UUID
  end
end
