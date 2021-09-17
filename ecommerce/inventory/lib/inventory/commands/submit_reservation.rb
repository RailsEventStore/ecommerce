module Inventory
  class SubmitReservation < Infra::Command
    attribute :order_id, Infra::Types::UUID
  end
end
