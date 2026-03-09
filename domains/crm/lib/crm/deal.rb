module Crm
  class Deal
    include AggregateRoot

    AlreadyCreated = Class.new(StandardError)
    NotFound = Class.new(StandardError)

    def initialize(id)
      @id = id
    end

    def create(pipeline_id, name)
      raise AlreadyCreated if @created
      apply DealCreated.new(data: { deal_id: @id, pipeline_id: pipeline_id, name: name })
    end

    def set_value(value)
      raise NotFound unless @created
      apply DealValueSet.new(data: { deal_id: @id, value: value })
    end

    def set_expected_close_date(expected_close_date)
      raise NotFound unless @created
      apply DealExpectedCloseDateSet.new(data: { deal_id: @id, expected_close_date: expected_close_date })
    end

    def move_to_stage(stage)
      raise NotFound unless @created
      apply DealMovedToStage.new(data: { deal_id: @id, stage: stage })
    end

    on DealCreated do |event|
      @created = true
    end

    on DealValueSet do |event|
    end

    on DealExpectedCloseDateSet do |event|
    end

    on DealMovedToStage do |event|
    end
  end
end
