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

  class PaymentIntentRegistered < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :intent_id, Infra::Types::String
  end

  class PaymentIntentActionRequired < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :intent_id, Infra::Types::String
    attribute :payment_method_id, Infra::Types::String
    attribute :client_secret, Infra::Types::String
  end

  class PaymentIntentFailed < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :intent_id, Infra::Types::String
    attribute :payment_method_id, Infra::Types::String
  end

  class PaymentIntentConfirmationRequired < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :intent_id, Infra::Types::String
    attribute :payment_method_id, Infra::Types::String
  end
end