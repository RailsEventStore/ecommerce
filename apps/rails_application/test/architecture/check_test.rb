require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/architecture/check"

class Architecture::CheckTest < Minitest::Test
  cover "Architecture*"

  def setup
    @tmp = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_returns_empty_result_when_no_boundaries
    write_config("read_models:\nbounded_contexts:\nprocesses:\n")
    result = run_check
    assert_empty(result.violations)
    assert_empty(result.new_violations)
    assert_equal(0, result.known_count)
  end

  def test_detects_cross_boundary_violation
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta::Thing.new\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    write_config(<<~YAML)
      read_models:
        - name: Alpha
          path: #{@tmp}/rm_a
        - name: Beta
          path: #{@tmp}/rm_b
    YAML
    result = run_check
    assert_equal(1, result.violations.size)
    assert_equal(1, result.new_violations.size)
    assert_equal(0, result.known_count)
  end

  def test_known_violations_are_filtered_out
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta::Thing.new\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    write_config(<<~YAML)
      read_models:
        - name: Alpha
          path: #{@tmp}/rm_a
          known_violations:
            - file: #{@tmp}/rm_a/file.rb
              constant: Beta::Thing
        - name: Beta
          path: #{@tmp}/rm_b
    YAML
    result = run_check
    assert_equal(1, result.violations.size)
    assert_empty(result.new_violations)
    assert_equal(1, result.known_count)
  end

  def test_missing_sections_do_not_break_loading
    write("bc/file.rb", "module Gamma\nend\n")
    write_config(<<~YAML)
      bounded_contexts:
        - name: Gamma
          path: #{@tmp}/bc
    YAML
    result = run_check
    assert_empty(result.violations)
  end

  def test_array_path_is_supported_in_config
    write("pm/main.rb", "module Processes\n  class Generator\n  end\nend\n")
    write("pm/extras/helper.rb", "module Processes\n  class Helper\n  end\nend\n")
    write_config(<<~YAML)
      processes:
        - name: Processes::Generator
          path:
            - #{@tmp}/pm/main.rb
            - #{@tmp}/pm/extras
    YAML
    result = run_check
    assert_empty(result.violations)
  end

  def test_read_model_to_bounded_context_is_allowed_by_type_default
    write("rm/file.rb", "module Alpha\n  class X\n    def call\n      Gamma::Event.new\n    end\n  end\nend\n")
    write("bc/file.rb", "module Gamma\nend\n")
    write_config(<<~YAML)
      read_models:
        - name: Alpha
          path: #{@tmp}/rm
      bounded_contexts:
        - name: Gamma
          path: #{@tmp}/bc
    YAML
    result = run_check
    assert_empty(result.violations)
  end

  def test_process_to_bounded_context_is_allowed_by_type_default
    write("pm/file.rb", "module Processes\n  class Apply\n    def call\n      Gamma::Event.new\n    end\n  end\nend\n")
    write("bc/file.rb", "module Gamma\nend\n")
    write_config(<<~YAML)
      processes:
        - name: Processes::Apply
          path: #{@tmp}/pm
      bounded_contexts:
        - name: Gamma
          path: #{@tmp}/bc
    YAML
    result = run_check
    assert_empty(result.violations)
  end

  def test_allowed_list_suppresses_violations
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta::Thing.new\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    write_config(<<~YAML)
      read_models:
        - name: Alpha
          path: #{@tmp}/rm_a
          allowed: [Beta]
        - name: Beta
          path: #{@tmp}/rm_b
    YAML
    result = run_check
    assert_empty(result.violations)
  end

  private

  def write(relative_path, content)
    full_path = File.join(@tmp, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def write_config(yaml)
    File.write(config_path, yaml)
  end

  def config_path
    File.join(@tmp, "architecture.yml")
  end

  def run_check
    Architecture::Check.run(config_path)
  end
end
