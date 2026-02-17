module Crm
  class Pipeline
    include AggregateRoot

    AlreadyCreated = Class.new(StandardError)
    NotFound = Class.new(StandardError)
    StageAlreadyExists = Class.new(StandardError)
    StageNotFound = Class.new(StandardError)

    def initialize(id)
      @id = id
      @stages = []
    end

    def create(name)
      raise AlreadyCreated if @created
      apply PipelineCreated.new(data: { pipeline_id: @id, name: name })
    end

    def add_stage(stage_name)
      raise NotFound unless @created
      raise StageAlreadyExists if @stages.include?(stage_name)
      apply StageAddedToPipeline.new(data: { pipeline_id: @id, stage_name: stage_name })
    end

    def remove_stage(stage_name)
      raise NotFound unless @created
      raise StageNotFound unless @stages.include?(stage_name)
      apply StageRemovedFromPipeline.new(data: { pipeline_id: @id, stage_name: stage_name })
    end

    on PipelineCreated do |event|
      @created = true
    end

    on StageAddedToPipeline do |event|
      @stages << event.data.fetch(:stage_name)
    end

    on StageRemovedFromPipeline do |event|
      @stages.delete(event.data.fetch(:stage_name))
    end
  end
end
