# frozen_string_literal: true

module Claims
  class ReportLoss
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :claim_id, :policy_id, :description

    alias aggregate_id claim_id

    def initialize(claim_id, policy_id, description)
      @claim_id = claim_id
      @policy_id = policy_id
      @description = description
      valid = UUID.match?(@claim_id) && UUID.match?(@policy_id) && @description.is_a?(String)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
