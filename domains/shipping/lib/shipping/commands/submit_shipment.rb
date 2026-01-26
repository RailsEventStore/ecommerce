module Shipping
  class SubmitShipment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end