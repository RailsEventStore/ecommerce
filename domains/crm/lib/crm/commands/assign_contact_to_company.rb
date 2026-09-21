module Crm
  class AssignContactToCompany
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i
    attr_reader :position_id, :contact_id, :company_id
    alias aggregate_id position_id

    def initialize(position_id, contact_id, company_id)
      @position_id = position_id
      @contact_id = contact_id
      @company_id = company_id
      valid = [@position_id, @contact_id, @company_id].all? { |id| id.is_a?(String) && UUID.match?(id) }
      raise Infra::Command::Invalid unless valid
    end
  end
end
