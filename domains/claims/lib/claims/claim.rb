# frozen_string_literal: true

module Claims
  class Claim
    include AggregateRoot

    InvalidState = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def report_loss(policy_id, description)
      raise InvalidState if @state
      apply LossReported.new(data: { claim_id: @id, policy_id: policy_id, description: description })
    end

    def assess_loss(amount)
      raise InvalidState unless @state.equal?(:reported)
      apply LossAssessed.new(data: { claim_id: @id, policy_id: @policy_id, amount: amount })
    end

    def settle(gateway)
      raise InvalidState unless @state.equal?(:assessed)
      gateway.pay_out(@id, @amount)
      apply ClaimSettled.new(data: { claim_id: @id, policy_id: @policy_id, amount: @amount })
    end

    on LossReported do |event|
      @state = :reported
      @policy_id = event.data.fetch(:policy_id)
    end

    on LossAssessed do |event|
      @state = :assessed
      @amount = event.data.fetch(:amount)
    end

    on ClaimSettled do |event|
      @state = :settled
    end
  end
end
