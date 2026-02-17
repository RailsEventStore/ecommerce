require_relative "test_helper"

module Crm
  class PipelineTest < Test
    cover "Crm*"

    def test_create_pipeline
      uid = SecureRandom.uuid
      assert_events("Crm::Pipeline$#{uid}", PipelineCreated.new(data: { pipeline_id: uid, name: "Sales" })) do
        create_pipeline(uid, "Sales")
      end
    end

    def test_cannot_create_same_pipeline_twice
      uid = SecureRandom.uuid
      create_pipeline(uid, "Sales")

      assert_raises(Pipeline::AlreadyCreated) do
        create_pipeline(uid, "Sales")
      end
    end

    def test_add_stage_to_pipeline
      uid = SecureRandom.uuid
      assert_events(
        "Crm::Pipeline$#{uid}",
        PipelineCreated.new(data: { pipeline_id: uid, name: "Sales" }),
        StageAddedToPipeline.new(data: { pipeline_id: uid, stage_name: "Prospecting" })
      ) do
        create_pipeline(uid, "Sales")
        add_stage_to_pipeline(uid, "Prospecting")
      end
    end

    def test_cannot_add_stage_to_nonexistent_pipeline
      uid = SecureRandom.uuid

      assert_raises(Pipeline::NotFound) do
        add_stage_to_pipeline(uid, "Prospecting")
      end
    end

    def test_cannot_add_duplicate_stage
      uid = SecureRandom.uuid
      create_pipeline(uid, "Sales")
      add_stage_to_pipeline(uid, "Prospecting")

      assert_raises(Pipeline::StageAlreadyExists) do
        add_stage_to_pipeline(uid, "Prospecting")
      end
    end

    def test_remove_stage_from_pipeline
      uid = SecureRandom.uuid
      assert_events(
        "Crm::Pipeline$#{uid}",
        PipelineCreated.new(data: { pipeline_id: uid, name: "Sales" }),
        StageAddedToPipeline.new(data: { pipeline_id: uid, stage_name: "Prospecting" }),
        StageRemovedFromPipeline.new(data: { pipeline_id: uid, stage_name: "Prospecting" })
      ) do
        create_pipeline(uid, "Sales")
        add_stage_to_pipeline(uid, "Prospecting")
        remove_stage_from_pipeline(uid, "Prospecting")
      end
    end

    def test_cannot_remove_stage_from_nonexistent_pipeline
      uid = SecureRandom.uuid

      assert_raises(Pipeline::NotFound) do
        remove_stage_from_pipeline(uid, "Prospecting")
      end
    end

    def test_cannot_remove_nonexistent_stage
      uid = SecureRandom.uuid
      create_pipeline(uid, "Sales")

      assert_raises(Pipeline::StageNotFound) do
        remove_stage_from_pipeline(uid, "Prospecting")
      end
    end

    private

    def create_pipeline(uid, name)
      run_command(CreatePipeline.new(pipeline_id: uid, name: name))
    end

    def add_stage_to_pipeline(uid, stage_name)
      run_command(AddStageToPipeline.new(pipeline_id: uid, stage_name: stage_name))
    end

    def remove_stage_from_pipeline(uid, stage_name)
      run_command(RemoveStageFromPipeline.new(pipeline_id: uid, stage_name: stage_name))
    end
  end
end
