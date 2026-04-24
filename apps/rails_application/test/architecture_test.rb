require "test_helper"
require_relative "../lib/architecture/check"

class ArchitectureTest < ActiveSupport::TestCase
  def test_no_new_boundary_violations
    result = Architecture::Check.run(Rails.root.join("config/architecture.yml"))
    assert_empty(result.new_violations, failure_message(result.new_violations))
  end

  private

  def failure_message(violations)
    grouped = violations.group_by { |v| [v.source, v.target] }
    lines = ["New boundary violations detected:"]
    grouped.sort_by { |(src, tgt), _| [src, tgt] }.each do |(src, tgt), vs|
      lines << "  #{src} -> #{tgt}:"
      vs.each { |v| lines << "    #{v.file}:#{v.line}  #{v.constant}" }
    end
    lines << ""
    lines << "Fix the reference or run: bin/architecture-check --baseline"
    lines.join("\n")
  end
end
