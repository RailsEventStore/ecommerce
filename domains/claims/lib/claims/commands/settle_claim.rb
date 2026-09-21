# frozen_string_literal: true

module Claims
  class SettleClaim
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :claim_id

    alias aggregate_id claim_id

    def initialize(claim_id)
      @claim_id = claim_id
      valid = UUID.match?(@claim_id)
    rescue TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
