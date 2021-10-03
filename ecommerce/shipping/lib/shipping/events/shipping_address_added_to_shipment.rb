module Shipping
  class ShippingAddressAddedToShipment < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :line_1, Infra::Types::String
    attribute :line_2, Infra::Types::String
    attribute :line_3, Infra::Types::String
    attribute :line_4, Infra::Types::String
  end
end
