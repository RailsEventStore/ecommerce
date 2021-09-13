module Payments
  class CapturePayment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end
