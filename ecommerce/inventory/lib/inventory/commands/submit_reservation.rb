module Inventory
  class SubmitReservation < Infra::Command
    attribute :order_id, Infra::Types::UUID
    attribute :reservation_items, Infra::Types::UUIDQuantityHash
  end
end
