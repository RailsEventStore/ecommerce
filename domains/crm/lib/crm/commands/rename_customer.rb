module Crm
  class RenameCustomer < Infra::Command
    attribute :customer_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    alias aggregate_id customer_id
  end
end
