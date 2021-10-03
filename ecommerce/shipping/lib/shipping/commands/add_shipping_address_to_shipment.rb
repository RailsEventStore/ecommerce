module Shipping
  class AddShippingAddressToShipment < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :line_1, Infra::Types::String
    attribute :line_2, Infra::Types::String
    attribute :line_3, Infra::Types::String
    attribute :line_4, Infra::Types::String

    alias aggregate_id order_id
  end
end
