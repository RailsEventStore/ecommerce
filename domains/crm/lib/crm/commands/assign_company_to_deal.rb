module Crm
  class AssignCompanyToDeal < Infra::Command
    attribute :deal_party_id, Infra::Types::UUID
    attribute :deal_id, Infra::Types::UUID
    attribute :company_id, Infra::Types::UUID
    alias aggregate_id deal_party_id
  end
end
