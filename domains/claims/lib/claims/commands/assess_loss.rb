# frozen_string_literal: true

module Claims
  class AssessLoss
    UUID = /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i

    attr_reader :claim_id, :amount

    alias aggregate_id claim_id

    def initialize(claim_id, amount)
      @claim_id = claim_id
      @amount = BigDecimal(amount)
      valid = UUID.match?(@claim_id) && @amount >= 0
    rescue ArgumentError, TypeError
      raise Infra::Command::Invalid
    else
      raise Infra::Command::Invalid unless valid
    end
  end
end
