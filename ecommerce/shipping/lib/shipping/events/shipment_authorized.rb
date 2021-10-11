module Shipping
  class ShipmentAuthorized < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end