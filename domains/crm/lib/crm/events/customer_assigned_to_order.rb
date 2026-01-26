module Crm
  class CustomerAssignedToOrder < Infra::Event
    attribute :customer_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
  end
end
