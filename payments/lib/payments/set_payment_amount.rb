module Payments
  class SetPaymentAmount < Command
    attribute :order_id, Types::UUID
    attribute :amount, Types::Nominal::Decimal
  end
end