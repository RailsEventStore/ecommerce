module Payments
  class SetPaymentAmount < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :amount, Infra::Types::Nominal::Decimal
  end

  class AuthorizePayment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end

  class CapturePayment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end

  class ReleasePayment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end
