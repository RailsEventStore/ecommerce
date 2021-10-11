module Shipping
  class ShipmentSubmitted < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end