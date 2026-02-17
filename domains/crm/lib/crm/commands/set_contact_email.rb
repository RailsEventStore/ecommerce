module Crm
  class SetContactEmail < Infra::Command
    attribute :contact_id, Infra::Types::UUID
    attribute :email, Infra::Types::String
    alias aggregate_id contact_id
  end
end
