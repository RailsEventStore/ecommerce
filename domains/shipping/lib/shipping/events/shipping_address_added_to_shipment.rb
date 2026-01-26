module Shipping
  class ShippingAddressAddedToShipment < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :postal_address, Infra::Types::PostalAddress
  end
end
