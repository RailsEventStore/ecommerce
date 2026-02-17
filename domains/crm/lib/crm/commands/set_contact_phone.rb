module Crm
  class SetContactPhone < Infra::Command
    attribute :contact_id, Infra::Types::UUID
    attribute :phone, Infra::Types::String
    alias aggregate_id contact_id
  end
end
