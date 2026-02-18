require "test_helper"

module Pipelines
  class PipelinesTest < InMemoryRESTestCase
    cover "Pipelines*"

    def test_pipeline_created
      create_pipeline(pipeline_id, "Sales")

      assert_equal(1, Pipelines.all.count)
      assert_equal("Sales", Pipelines.find_by_uid(pipeline_id).name)
    end

    def test_multiple_pipelines
      create_pipeline(pipeline_id, "Sales")
      create_pipeline(other_pipeline_id, "Support")

      assert_equal(2, Pipelines.all.count)
      assert_equal(["Sales", "Support"], Pipelines.all.map(&:name))
    end

    def test_stage_added
      create_pipeline(pipeline_id, "Sales")
      create_pipeline(other_pipeline_id, "Support")
      add_stage(pipeline_id, "Prospecting")

      assert_equal(["Prospecting"], Pipelines.stages_for(pipeline_id).map(&:stage_name))
      assert_equal([], Pipelines.stages_for(other_pipeline_id).map(&:stage_name))
    end

    def test_stage_removed
      create_pipeline(pipeline_id, "Sales")
      create_pipeline(other_pipeline_id, "Support")
      add_stage(other_pipeline_id, "Prospecting")
      add_stage(pipeline_id, "Negotiation")
      add_stage(pipeline_id, "Prospecting")
      remove_stage(pipeline_id, "Prospecting")

      assert_equal(["Negotiation"], Pipelines.stages_for(pipeline_id).map(&:stage_name))
      assert_equal(["Prospecting"], Pipelines.stages_for(other_pipeline_id).map(&:stage_name))
    end

    def test_stages_for_pipeline
      create_pipeline(pipeline_id, "Sales")
      create_pipeline(other_pipeline_id, "Support")
      add_stage(other_pipeline_id, "Triage")
      add_stage(pipeline_id, "Prospecting")
      add_stage(pipeline_id, "Negotiation")

      assert_equal(["Prospecting", "Negotiation"], Pipelines.stages_for(pipeline_id).map(&:stage_name))
      assert_equal(["Triage"], Pipelines.stages_for(other_pipeline_id).map(&:stage_name))
    end

    private

    def pipeline_id
      @pipeline_id ||= SecureRandom.uuid
    end

    def other_pipeline_id
      @other_pipeline_id ||= SecureRandom.uuid
    end

    def create_pipeline(uid, name)
      event_store.publish(Crm::PipelineCreated.new(data: { pipeline_id: uid, name: name }))
    end

    def add_stage(uid, stage_name)
      event_store.publish(Crm::StageAddedToPipeline.new(data: { pipeline_id: uid, stage_name: stage_name }))
    end

    def remove_stage(uid, stage_name)
      event_store.publish(Crm::StageRemovedFromPipeline.new(data: { pipeline_id: uid, stage_name: stage_name }))
    end
  end
end
