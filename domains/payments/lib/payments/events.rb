module Payments
  class PaymentAmountSet < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :amount, Infra::Types::Nominal::Decimal
  end

  class PaymentAuthorized < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end

  class PaymentCaptured < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end

  class PaymentReleased < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
