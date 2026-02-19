module Crm
  class AssignCompanyToDeal < Infra::Command
    attribute :deal_id, Infra::Types::UUID
    attribute :company_id, Infra::Types::UUID
    alias aggregate_id deal_id
  end
end
