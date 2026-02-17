module Crm
  class RegisterCompany < Infra::Command
    attribute :company_id, Infra::Types::UUID
    attribute :name, Infra::Types::String
    alias aggregate_id company_id
  end
end
