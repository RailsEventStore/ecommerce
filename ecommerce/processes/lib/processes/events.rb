module Processes
  class ReservationProcessFailed < Infra::Event
    attribute :order_id, Infra::Types::UUID
    attribute :unavailable_products, Infra::Types::Array
  end

  class ReservationProcessSuceeded < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end
