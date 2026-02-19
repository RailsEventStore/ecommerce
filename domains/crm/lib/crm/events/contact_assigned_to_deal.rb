module Crm
  class ContactAssignedToDeal < Infra::Event
    attribute :deal_id, Infra::Types::UUID
    attribute :contact_id, Infra::Types::UUID
  end
end
