module Crm
  class ContactAssignedToCompany < Infra::Event
    attribute :position_id, Infra::Types::UUID
    attribute :contact_id, Infra::Types::UUID
    attribute :company_id, Infra::Types::UUID
  end
end
