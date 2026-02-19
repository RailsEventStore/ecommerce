module Crm
  class AssignContactToCompany < Infra::Command
    attribute :contact_id, Infra::Types::UUID
    attribute :company_id, Infra::Types::UUID
    alias aggregate_id contact_id
  end
end
