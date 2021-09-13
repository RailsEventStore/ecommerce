module Payments
  class SetPaymentAmount < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :amount,   Infra::Types::Nominal::Decimal
  end
end