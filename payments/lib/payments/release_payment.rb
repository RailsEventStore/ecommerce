module Payments
  class ReleasePayment < Command
    attribute :order_id, Types::UUID
  end
end
