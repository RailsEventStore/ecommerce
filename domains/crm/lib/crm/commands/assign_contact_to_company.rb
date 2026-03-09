module Crm
  class AssignContactToCompany < Infra::Command
    attribute :position_id, Infra::Types::UUID
    attribute :contact_id, Infra::Types::UUID
    attribute :company_id, Infra::Types::UUID
    alias aggregate_id position_id
  end
end
