require "test_helper"
require "yaml"

class CiWorkflowTest < ActiveSupport::TestCase
  def workflow_file_path
    Rails.root.join("../.github/workflows/rails_application.yml")
  end

  def workflow_config
    YAML.load_file(workflow_file_path)
  end

  def test_workflow_file_exists
    assert(File.exist?(workflow_file_path), "CI workflow file does not exist at #{workflow_file_path}")
  end

  def test_workflow_has_release_job
    assert(workflow_config.dig("jobs", "release"), "Workflow must have a 'release' job")
  end

  def test_release_job_depends_on_test_job
    assert(workflow_config.dig("jobs", "release", "needs"), "Release job must have 'needs' dependency")
    assert_includes(Array(workflow_config.dig("jobs", "release", "needs")), "test", "Release job must depend on 'test' job")
  end

  def test_release_job_only_runs_on_master
    assert(workflow_config.dig("jobs", "release", "if"), "Release job must have an 'if' condition")
    assert_match(/master/, workflow_config.dig("jobs", "release", "if"), "Release job must be conditional on master branch")
  end

  def test_release_job_has_deployment_steps
    assert(workflow_config.dig("jobs", "release", "steps"), "Release job must have steps")
    assert(workflow_config.dig("jobs", "release", "steps").any?, "Release job must have at least one step")
    assert(workflow_config.dig("jobs", "release", "steps").find { |step| step["uses"]&.include?("heroku-deploy") }, "Release job must include heroku-deploy action")
  end

  def test_release_job_has_heroku_app_name
    assert(workflow_config.dig("jobs", "release", "steps").find { |step| step["uses"]&.include?("heroku-deploy") }.dig("with", "heroku_app_name"), "Heroku deploy step must specify heroku_app_name")
    refute_empty(workflow_config.dig("jobs", "release", "steps").find { |step| step["uses"]&.include?("heroku-deploy") }.dig("with", "heroku_app_name"), "Heroku app name must not be empty")
  end

  def test_workflow_triggers_on_push_to_master
    assert(workflow_config[true], "Workflow must have trigger configuration")
    assert(workflow_config[true]["push"] || workflow_config[true].include?("push"), "Workflow must trigger on push events")
  end

  def test_no_orphaned_deploy_job
    assert(workflow_config["jobs"], "Workflow must have jobs")
    if workflow_config["jobs"].key?("deploy")
      if workflow_config["jobs"].dig("deploy", "uses")&.start_with?("./")
        assert(File.exist?(Rails.root.join("../.github/workflows", workflow_config["jobs"].dig("deploy", "uses").sub("./", ""))), "Deploy job references non-existent workflow file: #{Rails.root.join("../.github/workflows", workflow_config["jobs"].dig("deploy", "uses").sub("./", ""))}")
      end
    end
  end
end
