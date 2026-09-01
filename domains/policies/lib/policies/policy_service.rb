# frozen_string_literal: true

module Policies
  class OnIssuePolicy
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Policy, command.aggregate_id) do |policy|
        policy.issue(command.premium)
      end
    end
  end

  class OnPutPolicyInForce
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Policy, command.aggregate_id) do |policy|
        policy.put_in_force
      end
    end
  end

  class OnTerminatePolicy
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Policy, command.aggregate_id) do |policy|
        policy.terminate
      end
    end
  end
end
