module Crm
  class CompanyAssignedToDeal < Infra::Event
    attribute :deal_party_id, Infra::Types::UUID
    attribute :deal_id, Infra::Types::UUID
    attribute :company_id, Infra::Types::UUID
  end
end
