module Inventory
  class AdjustReservation < Command
    attribute :order_id, Types::UUID
    attribute :product_id, Types::UUID
    attribute :quantity, Types::Integer
  end
end