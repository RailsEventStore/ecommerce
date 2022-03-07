module Ordering
  class OrderArchived < Infra::Event
    attribute :order_id, Infra::Types::UUID
  end
end