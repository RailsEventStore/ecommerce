# frozen_string_literal: true

module Underwriting
  class OnSubmitApplication
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(InsuranceApplication, command.aggregate_id) do |application|
        application.submit(command.coverage_amount)
      end
    end
  end

  class OnEvaluateRisk
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(InsuranceApplication, command.aggregate_id) do |application|
        application.evaluate_risk(command.risk_class)
      end
    end
  end

  class OnCalculatePremium
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(InsuranceApplication, command.aggregate_id) do |application|
        application.calculate_premium
      end
    end
  end

  class OnAcceptOffer
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(InsuranceApplication, command.aggregate_id) do |application|
        application.accept_offer
      end
    end
  end
end
