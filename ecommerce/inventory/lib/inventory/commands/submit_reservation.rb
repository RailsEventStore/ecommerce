module Inventory
  class SubmitReservation < Command
    attribute :order_id, Types::UUID
  end
end