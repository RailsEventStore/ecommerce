module Inventory
  class CancelReservation < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end
