module Payments
  class CapturePayment < Command
    attribute :order_id, Types::UUID
  end
end
