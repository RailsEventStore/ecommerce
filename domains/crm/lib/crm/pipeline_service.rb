module Crm
  class OnCreatePipeline
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Pipeline, command.aggregate_id) do |pipeline|
        pipeline.create(command.name)
      end
    end
  end

  class OnAddStageToPipeline
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Pipeline, command.aggregate_id) do |pipeline|
        pipeline.add_stage(command.stage_name)
      end
    end
  end

  class OnRemoveStageFromPipeline
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      @repository.with_aggregate(Pipeline, command.aggregate_id) do |pipeline|
        pipeline.remove_stage(command.stage_name)
      end
    end
  end
end
