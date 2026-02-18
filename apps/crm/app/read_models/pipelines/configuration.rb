module Pipelines
  class Pipeline < ApplicationRecord
    self.table_name = "pipelines"
  end
  private_constant :Pipeline

  class Stage < ApplicationRecord
    self.table_name = "pipeline_stages"
  end
  private_constant :Stage

  def self.all
    Pipeline.order(id: :asc)
  end

  def self.find_by_uid(uid)
    Pipeline.find_by!(uid: uid)
  end

  def self.stages_for(pipeline_uid)
    Stage.where(pipeline_uid: pipeline_uid).order(id: :asc)
  end

  class CreatePipeline
    def call(event)
      Pipeline.create!(
        uid: event.data.fetch(:pipeline_id),
        name: event.data.fetch(:name)
      )
    end
  end

  class AddStage
    def call(event)
      Stage.create!(
        pipeline_uid: event.data.fetch(:pipeline_id),
        stage_name: event.data.fetch(:stage_name)
      )
    end
  end

  class RemoveStage
    def call(event)
      Stage.find_by!(
        pipeline_uid: event.data.fetch(:pipeline_id),
        stage_name: event.data.fetch(:stage_name)
      ).destroy!
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreatePipeline.new, to: [Crm::PipelineCreated])
      event_store.subscribe(AddStage.new, to: [Crm::StageAddedToPipeline])
      event_store.subscribe(RemoveStage.new, to: [Crm::StageRemovedFromPipeline])
    end
  end
end
