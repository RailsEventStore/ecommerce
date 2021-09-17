module Inventory
  class AdjustReservation < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :product_id, Infra::Types::UUID
    attribute :quantity, Infra::Types::Integer
  end
end
