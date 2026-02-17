module Crm
  class ContactLinkedinUrlSet < Infra::Event
    attribute :contact_id, Infra::Types::UUID
    attribute :linkedin_url, Infra::Types::String
  end
end
