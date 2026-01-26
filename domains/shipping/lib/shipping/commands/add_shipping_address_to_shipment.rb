module Shipping
  class AddShippingAddressToShipment < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :postal_address, Infra::Types::PostalAddress

    alias aggregate_id order_id
  end
end
