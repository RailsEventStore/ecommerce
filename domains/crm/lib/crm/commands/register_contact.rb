module Crm
  class RegisterContact < Infra::Command
    attribute :contact_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    alias aggregate_id contact_id
  end
end
