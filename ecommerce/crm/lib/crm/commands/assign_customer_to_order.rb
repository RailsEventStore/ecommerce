module Crm
  class AssignCustomerToOrder < Infra::Command
    attribute :customer_id, Infra::Types::UUID
    attribute :order_id, Infra::Types::UUID
    alias aggregate_id order_id
  end
end
