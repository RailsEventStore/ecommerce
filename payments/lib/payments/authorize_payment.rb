module Payments
  class AuthorizePayment < Command
    attribute :order_id, Types::UUID
  end
end
