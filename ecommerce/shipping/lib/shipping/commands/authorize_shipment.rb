module Shipping
  class AuthorizeShipment < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end