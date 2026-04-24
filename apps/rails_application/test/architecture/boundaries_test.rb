require "test_helper"
require "tmpdir"
require "fileutils"
require_relative "../../lib/architecture/boundaries"

class Architecture::BoundariesTest < Minitest::Test
  cover "Architecture*"

  def setup
    @tmp = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def test_empty_config_returns_no_violations
    assert_empty(check)
  end

  def test_boundary_with_no_files_returns_no_violations
    assert_empty(check(boundary("Alpha", "read_model", "empty_dir")))
  end

  def test_internal_references_are_not_flagged
    write("rm/alpha.rb", <<~RUBY)
      module Alpha
        class Inner
          def call
            Alpha::Other.new
          end
        end
      end
    RUBY
    assert_empty(check(boundary("Alpha", "read_model", "rm")))
  end

  def test_cross_boundary_reference_is_flagged
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta::Thing.new\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    violations = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Alpha", violations.first.source)
    assert_equal("Beta", violations.first.target)
    assert_equal("Beta::Thing", violations.first.constant)
    assert_equal(4, violations.first.line)
  end

  def test_read_model_to_bounded_context_is_allowed_by_default
    write("rm/file.rb", "module Alpha\n  class X\n    def call\n      Gamma::Event.new\n    end\n  end\nend\n")
    write("bc/file.rb", "module Gamma\nend\n")
    assert_empty(check(
      boundary("Alpha", "read_model", "rm"),
      boundary("Gamma", "bounded_context", "bc"),
    ))
  end

  def test_bounded_context_to_bounded_context_is_flagged
    write("bc_a/file.rb", "module Gamma\n  class X\n    def call\n      Delta::Event.new\n    end\n  end\nend\n")
    write("bc_b/file.rb", "module Delta\nend\n")
    violations = check(
      boundary("Gamma", "bounded_context", "bc_a"),
      boundary("Delta", "bounded_context", "bc_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Gamma", violations.first.source)
    assert_equal("Delta", violations.first.target)
  end

  def test_bounded_context_to_read_model_is_flagged
    write("bc/file.rb", "module Gamma\n  class X\n    def call\n      Alpha::Thing.new\n    end\n  end\nend\n")
    write("rm/file.rb", "module Alpha\nend\n")
    violations = check(
      boundary("Gamma", "bounded_context", "bc"),
      boundary("Alpha", "read_model", "rm"),
    )
    assert_equal(1, violations.size)
    assert_equal("Alpha", violations.first.target)
  end

  def test_process_to_bounded_context_is_allowed_by_default
    write("pm/file.rb", "module Processes\n  class Apply\n    def call\n      Gamma::Event.new\n    end\n  end\nend\n")
    write("bc/file.rb", "module Gamma\nend\n")
    assert_empty(check(
      boundary("Processes::Apply", "process", "pm"),
      boundary("Gamma", "bounded_context", "bc"),
    ))
  end

  def test_process_to_read_model_is_flagged
    write("pm/file.rb", "module Processes\n  class Apply\n    def call\n      Alpha.thing\n    end\n  end\nend\n")
    write("rm/file.rb", "module Alpha\nend\n")
    violations = check(
      boundary("Processes::Apply", "process", "pm"),
      boundary("Alpha", "read_model", "rm"),
    )
    assert_equal(1, violations.size)
    assert_equal("Alpha", violations.first.target)
  end

  def test_process_to_process_is_flagged
    write("pm_a/file.rb", "module Processes\n  class Apply\n    def call\n      Processes::Ship.new\n    end\n  end\nend\n")
    write("pm_b/file.rb", "module Processes\n  class Ship\n  end\nend\n")
    violations = check(
      boundary("Processes::Apply", "process", "pm_a"),
      boundary("Processes::Ship", "process", "pm_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Processes::Apply", violations.first.source)
    assert_equal("Processes::Ship", violations.first.target)
  end

  def test_explicit_allowed_list_suppresses_violation
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta::Thing.new\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    assert_empty(check(
      boundary("Alpha", "read_model", "rm_a", ["Beta"]),
      boundary("Beta", "read_model", "rm_b"),
    ))
  end

  def test_module_declaration_is_not_flagged_as_reference
    write("rm/file.rb", "module Alpha\n  module Beta\n  end\nend\n")
    write("other/file.rb", "module Beta\nend\n")
    assert_empty(check(
      boundary("Alpha", "read_model", "rm"),
      boundary("Beta", "read_model", "other"),
    ))
  end

  def test_class_declaration_is_not_flagged_as_reference
    write("rm/file.rb", "module Alpha\n  class Beta\n  end\nend\n")
    write("other/file.rb", "module Beta\nend\n")
    assert_empty(check(
      boundary("Alpha", "read_model", "rm"),
      boundary("Beta", "read_model", "other"),
    ))
  end

  def test_superclass_reference_is_flagged
    write("rm_a/file.rb", "module Alpha\n  class X < Beta::Base\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\n  class Base\n  end\nend\n")
    violations = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Beta::Base", violations.first.constant)
  end

  def test_nested_module_reference_resolves_locally
    write("pm/main.rb", <<~RUBY)
      module Processes
        class Generator
          def call
            Invoices::Splitter.new
          end
        end
      end
    RUBY
    write("pm/invoices/splitter.rb", <<~RUBY)
      module Processes
        module Invoices
          class Splitter
          end
        end
      end
    RUBY
    write("rm/file.rb", "module Invoices\nend\n")
    assert_empty(check(
      boundary("Processes::Generator", "process", ["pm/main.rb", "pm/invoices"]),
      boundary("Invoices", "read_model", "rm"),
    ))
  end

  def test_multi_path_combines_files_and_directories
    write("pm/main.rb", "module Processes\n  class Generator\n  end\nend\n")
    write("pm/extras/helper.rb", "module Processes\n  class Helper\n  end\nend\n")
    boundaries = Architecture::Boundaries.new([
      Architecture::Boundary.new(
        name: "Processes::Generator",
        type: "process",
        paths: [File.join(@tmp, "pm/main.rb"), File.join(@tmp, "pm/extras")],
        allowed: [],
      ),
    ])
    assert_empty(boundaries.check)
  end

  def test_longest_prefix_matching_prefers_specific_boundary
    write("parent/file.rb", "module Processes\n  class Caller\n    def call\n      Processes::Apply.new\n    end\n  end\nend\n")
    write("target/file.rb", "module Processes\n  class Apply\n  end\nend\n")
    violations = check(
      boundary("Processes::Caller", "process", "parent"),
      boundary("Processes::Apply", "process", "target"),
    )
    assert_equal(1, violations.size)
    assert_equal("Processes::Apply", violations.first.target)
  end

  def test_reference_to_unknown_namespace_is_ignored
    write("rm/file.rb", "module Alpha\n  class X\n    def call\n      SomeGem::Thing.new\n    end\n  end\nend\n")
    assert_empty(check(boundary("Alpha", "read_model", "rm")))
  end

  def test_violation_captures_file_line_and_column
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta::Thing.new\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    violation = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    ).first
    assert_equal(File.join(@tmp, "rm_a/file.rb"), violation.file)
    assert_equal(4, violation.line)
    assert_equal(6, violation.column)
  end

  def test_bare_constant_reference_resolves_via_nesting_to_sibling_boundary
    write("pm_a/file.rb", "module Processes\n  class Apply\n    def call\n      Ship.new\n    end\n  end\nend\n")
    write("pm_b/file.rb", "module Processes\n  class Ship\n  end\nend\n")
    violations = check(
      boundary("Processes::Apply", "process", "pm_a"),
      boundary("Processes::Ship", "process", "pm_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Processes::Ship", violations.first.target)
    assert_equal("Processes::Ship", violations.first.constant)
  end

  def test_deeply_nested_scope_preserves_outer_nesting
    write("outer/file.rb", <<~RUBY)
      module Outer
        module Sibling
        end
        module Middle
          class Inner
            def call
              Sibling.new
            end
          end
        end
      end
    RUBY
    write("other/file.rb", "module Sibling\nend\n")
    assert_empty(check(
      boundary("Outer", "read_model", "outer"),
      boundary("Sibling", "read_model", "other"),
    ))
  end

  def test_nested_class_scope_is_tracked_for_resolution
    write("outer/file.rb", <<~RUBY)
      module Outer
        class Inner
          class Target
          end
          def call
            Target.new
          end
        end
      end
    RUBY
    write("other/file.rb", "module Target\nend\n")
    assert_empty(check(
      boundary("Outer", "read_model", "outer"),
      boundary("Target", "read_model", "other"),
    ))
  end

  def test_multi_segment_constant_reference_is_resolved_by_top_segment
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta::Nested::Deep.new\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    violations = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Beta::Nested::Deep", violations.first.constant)
    assert_equal("Beta", violations.first.target)
  end

  def test_single_file_path_boundary_is_scanned
    write("pm.rb", <<~RUBY)
      module Processes
        class Generator
          def call
            Alpha::Thing.new
          end
        end
      end
    RUBY
    write("rm/alpha.rb", "module Alpha\nend\n")
    violations = check(
      boundary("Processes::Generator", "process", "pm.rb"),
      boundary("Alpha", "read_model", "rm"),
    )
    assert_equal(1, violations.size)
    assert_equal("Alpha", violations.first.target)
  end

  def test_superclass_violation_captures_correct_file
    write("rm_a/definition.rb", "module Alpha\n  class X < Beta::Base\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\n  class Base\n  end\nend\n")
    violation = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    ).first
    assert_equal(File.join(@tmp, "rm_a/definition.rb"), violation.file)
  end

  def test_top_level_boundary_match_when_nesting_has_no_local_declaration
    write("rm_a/file.rb", "module Alpha\n  class X\n    def call\n      Beta.thing\n    end\n  end\nend\n")
    write("rm_b/file.rb", "module Beta\nend\n")
    violation = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    ).first
    assert_equal("Beta", violation.target)
    assert_equal("Beta", violation.constant)
  end

  def test_boundary_matched_via_name_only_when_no_files_declare_it
    write("caller/file.rb", "module Processes\n  class Caller\n    def call\n      Apply.new\n    end\n  end\nend\n")
    FileUtils.mkdir_p(File.join(@tmp, "empty"))
    violations = check(
      boundary("Processes::Caller", "process", "caller"),
      boundary("Processes::Apply", "process", "empty"),
    )
    assert_equal(1, violations.size)
    assert_equal("Processes::Apply", violations.first.target)
    assert_equal("Processes::Apply", violations.first.constant)
  end

  def test_local_declaration_skip_runs_before_target_match
    write("rm_a/file.rb", <<~RUBY)
      module Alpha
        class Inner
          def call
            Inner.new
          end
        end
      end
    RUBY
    write("rm_b/file.rb", "module Alpha::Inner\nend\n")
    assert_empty(check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Alpha::Inner", "read_model", "rm_b"),
    ))
  end

  def test_resolves_via_intermediate_namespace_when_full_reference_not_declared
    write("pm/file.rb", <<~RUBY)
      module Processes
        module Invoices
        end
        class Generator
          def call
            Invoices::NotDeclared.new
          end
        end
      end
    RUBY
    write("rm/file.rb", "module Invoices\nend\n")
    assert_empty(check(
      boundary("Processes::Generator", "process", "pm"),
      boundary("Invoices", "read_model", "rm"),
    ))
  end

  def test_deep_nested_file_in_directory_path_is_scanned
    write("rm_a/deep/nested/file.rb", <<~RUBY)
      module Alpha
        class Deep
          def call
            Beta::Thing.new
          end
        end
      end
    RUBY
    write("rm_b/file.rb", "module Beta\nend\n")
    violations = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Beta::Thing", violations.first.constant)
  end

  def test_only_same_source_declarations_block_cross_boundary_check
    write("rm_a/file.rb", <<~RUBY)
      module Alpha
        class X
          def call
            Beta::Thing.new
          end
        end
      end
    RUBY
    write("rm_b/file.rb", "module Beta\n  class Thing\n  end\nend\n")
    violations = check(
      boundary("Alpha", "read_model", "rm_a"),
      boundary("Beta", "read_model", "rm_b"),
    )
    assert_equal(1, violations.size)
    assert_equal("Beta::Thing", violations.first.constant)
  end

  private

  def write(relative_path, content)
    full_path = File.join(@tmp, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
  end

  def boundary(name, type, path, allowed = [])
    paths = Array(path).map { |p| File.join(@tmp, p) }
    { name: name, type: type, paths: paths, allowed: allowed }
  end

  def check(*configs)
    Architecture::Boundaries.new(
      configs.map { |c| Architecture::Boundary.new(name: c[:name], type: c[:type], paths: c[:paths], allowed: c[:allowed]) }
    ).check
  end
end
