module Crm
  class OnCreateDeal
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Deal, command.aggregate_id) do |deal|
        deal.create(command.pipeline_id, command.name)
      end
    end
  end

  class OnSetDealValue
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Deal, command.aggregate_id) do |deal|
        deal.set_value(command.value)
      end
    end
  end

  class OnSetDealExpectedCloseDate
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Deal, command.aggregate_id) do |deal|
        deal.set_expected_close_date(command.expected_close_date)
      end
    end
  end

  class OnMoveDealToStage
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Deal, command.aggregate_id) do |deal|
        deal.move_to_stage(command.stage)
      end
    end
  end
end
