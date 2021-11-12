module Inventory
  class CheckAvailability < Infra::Command
    attribute :product_id, Infra::Types::UUID
    attribute :desired_quantity, Infra::Types::Integer
  end
end