module Crm
  class ContactPhoneSet < Infra::Event
    attribute :contact_id, Infra::Types::UUID
    attribute :phone, Infra::Types::String
  end
end
