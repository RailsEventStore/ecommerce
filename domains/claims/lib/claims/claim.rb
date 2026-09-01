# frozen_string_literal: true

module Claims
  class Claim
    include AggregateRoot

    InvalidState = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def report_damage(policy_id, description)
      raise InvalidState if @state
      apply DamageReported.new(data: { claim_id: @id, policy_id: policy_id, description: description })
    end

    def evaluate_damage(amount)
      raise InvalidState unless @state.equal?(:reported)
      apply DamageEvaluated.new(data: { claim_id: @id, policy_id: @policy_id, amount: amount })
    end

    def pay_compensation(gateway)
      raise InvalidState unless @state.equal?(:evaluated)
      gateway.pay_out(@id, @amount)
      apply CompensationPaid.new(data: { claim_id: @id, policy_id: @policy_id, amount: @amount })
    end

    on DamageReported do |event|
      @state = :reported
      @policy_id = event.data.fetch(:policy_id)
    end

    on DamageEvaluated do |event|
      @state = :evaluated
      @amount = event.data.fetch(:amount)
    end

    on CompensationPaid do |event|
      @state = :paid
    end
  end
end
