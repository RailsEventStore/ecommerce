require "test_helper"
require "open3"
require "tmpdir"
require "fileutils"

class ResetHerokuDbTest < ActiveSupport::TestCase
  def setup
    @tmp = Dir.mktmpdir
    File.write(File.join(@tmp, "heroku"), <<~SH)
      #!/bin/sh
      if [ "$1" = "$FAIL_COMMAND" ]; then
        if [ "$1" != "run" ]; then
          exit 42
        fi
        for argument do
          if [ "$argument" = "--exit-code" ]; then
            exit 42
          fi
        done
      fi
      case "$1" in
        maintenance:on|maintenance:off)
          printf '%s' "$1" > "$MAINTENANCE_STATE"
          ;;
      esac
    SH
    File.chmod(0755, File.join(@tmp, "heroku"))
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_success_reopens_the_application
    assert_equal(0, run_reset.exitstatus)
    assert_equal("maintenance:off", File.read(maintenance_state))
  end

  def test_failure_stops_the_reset_and_keeps_maintenance_enabled
    ["ps:restart", "pg:reset", "run"].each do |command|
      assert_equal(42, run_reset(command).exitstatus, command)
      assert_equal("maintenance:on", File.read(maintenance_state), command)
    end
  end

  private

  def run_reset(fail_command = "")
    Open3.capture3(
      { "PATH" => "#{@tmp}:#{ENV.fetch('PATH')}", "FAIL_COMMAND" => fail_command, "MAINTENANCE_STATE" => maintenance_state },
      Rails.root.join("bin/reset_heroku_db.sh").to_s
    ).last
  end

  def maintenance_state
    File.join(@tmp, "maintenance")
  end
end
