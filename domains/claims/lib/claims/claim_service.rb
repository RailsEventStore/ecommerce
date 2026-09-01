# frozen_string_literal: true

module Claims
  class OnReportLoss
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Claim, command.aggregate_id) do |claim|
        claim.report_loss(command.policy_id, command.description)
      end
    end
  end

  class OnAssessLoss
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Claim, command.aggregate_id) do |claim|
        claim.assess_loss(command.amount)
      end
    end
  end

  class OnSettleClaim
    def initialize(event_store, gateway)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @gateway = gateway
    end

    def call(command)
      @repository.with_aggregate(Claim, command.aggregate_id) do |claim|
        claim.settle(@gateway.call)
      end
    end
  end
end
