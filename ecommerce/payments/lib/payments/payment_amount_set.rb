module Payments
  class PaymentAmountSet < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :amount,   Infra::Types::Nominal::Decimal
  end
end