module Inventory
  class CompleteReservation < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end