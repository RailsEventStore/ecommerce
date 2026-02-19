module Crm
  class AssignContactToDeal < Infra::Command
    attribute :deal_id, Infra::Types::UUID
    attribute :contact_id, Infra::Types::UUID
    alias aggregate_id deal_id
  end
end
