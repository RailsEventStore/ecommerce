module Crm
  class ContactRegistered < Infra::Event
    attribute :contact_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end
end
