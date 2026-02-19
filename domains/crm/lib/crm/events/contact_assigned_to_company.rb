module Crm
  class ContactAssignedToCompany < Infra::Event
    attribute :contact_id, Infra::Types::UUID
    attribute :company_id, Infra::Types::UUID
  end
end
