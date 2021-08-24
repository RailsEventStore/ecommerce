module Inventory
  class CompleteReservation < Command
    attribute :order_id, Types::UUID
  end
end