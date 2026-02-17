module Crm
  class SetContactLinkedinUrl < Infra::Command
    attribute :contact_id, Infra::Types::UUID
    attribute :linkedin_url, Infra::Types::String
    alias aggregate_id contact_id
  end
end
