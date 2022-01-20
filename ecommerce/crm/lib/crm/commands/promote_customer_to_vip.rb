module Crm
  class PromoteCustomerToVip < Infra::Command
    attribute :customer_id, Infra::Types::UUID
    alias aggregate_id customer_id
  end
end
