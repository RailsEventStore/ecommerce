module Payments
  class PaymentAuthorized < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
