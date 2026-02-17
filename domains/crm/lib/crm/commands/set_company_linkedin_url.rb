module Crm
  class SetCompanyLinkedinUrl < Infra::Command
    attribute :company_id, Infra::Types::UUID
    attribute :linkedin_url, Infra::Types::String
    alias aggregate_id company_id
  end
end
