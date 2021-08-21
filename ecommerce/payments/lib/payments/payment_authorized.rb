module Payments
  class PaymentAuthorized < Event
    attribute :order_id,       Types::UUID
  end
end
