module Processes
  class ReservationProcessFailed < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :unavailable_products, Infra::Types::Array.of(Infra::Types::UUID)
  end

  class ReservationProcessSuceeded < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
