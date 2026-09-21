module Crm
  class AssignContactToDeal
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :deal_party_id, :deal_id, :contact_id
    alias aggregate_id deal_party_id

    def initialize(deal_party_id, deal_id, contact_id)
      @deal_party_id = deal_party_id
      @deal_id = deal_id
      @contact_id = contact_id
      valid = [@deal_party_id, @deal_id, @contact_id].all? { |id| id.is_a?(String) && UUID.match?(id) }
      raise Infra::Command::Invalid unless valid
    end
  end
end
