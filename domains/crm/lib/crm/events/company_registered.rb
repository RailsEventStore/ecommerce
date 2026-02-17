module Crm
  class CompanyRegistered < Infra::Event
    attribute :company_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
  end
end
