module Crm
  class ContactEmailSet < Infra::Event
    attribute :contact_id, Infra::Types::UUID
    attribute :email, Infra::Types::String
  end
end
