module Payments
  class AuthorizePayment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end
