# frozen_string_literal: true

module Claims
  class OnReportDamage
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Claim, command.aggregate_id) do |claim|
        claim.report_damage(command.policy_id, command.description)
      end
    end
  end

  class OnEvaluateDamage
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Claim, command.aggregate_id) do |claim|
        claim.evaluate_damage(command.amount)
      end
    end
  end

  class OnPayCompensation
    def initialize(event_store, gateway)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @gateway = gateway
    end

    def call(command)
      @repository.with_aggregate(Claim, command.aggregate_id) do |claim|
        claim.pay_compensation(@gateway.call)
      end
    end
  end
end
