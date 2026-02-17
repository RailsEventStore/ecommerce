module Crm
  class CompanyLinkedinUrlSet < Infra::Event
    attribute :company_id, Infra::Types::UUID
    attribute :linkedin_url, Infra::Types::String
  end
end
