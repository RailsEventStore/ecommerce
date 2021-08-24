module Inventory
  class CancelReservation < Command
    attribute :order_id, Types::UUID
  end
end