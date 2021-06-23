module Payments
  class PaymentAmountSet < Event
    attribute :order_id, Types::UUID
    attribute :amount,   Types::Nominal::Decimal
  end
end