module Crm
  class CustomerRegistered < Infra::Event
    attribute :customer_id, Infra::Types::UUID
    attribute :name,       Infra::Types::String
  end
end


