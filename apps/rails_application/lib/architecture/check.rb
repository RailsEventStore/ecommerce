require "yaml"
require "set"
require_relative "boundaries"

module Architecture
  module Check
    SECTIONS = {
      "read_models" => "read_model",
      "bounded_contexts" => "bounded_context",
      "processes" => "process",
    }.freeze

    Result = Data.define(:violations, :new_violations, :known_count)

    def self.run(config_path)
      config = YAML.safe_load_file(config_path)
      violations = Boundaries.new(build_boundaries(config)).check
      known = build_known(config)
      new_violations = violations.reject { |v| known[v.source].include?([v.file, v.constant]) }
      Result.new(
        violations: violations,
        new_violations: new_violations,
        known_count: violations.size - new_violations.size,
      )
    end

    def self.build_boundaries(config)
      SECTIONS.flat_map do |section, type|
        (config[section] || []).map do |b|
          Boundary.new(
            name: b.fetch("name"),
            type: type,
            paths: Array(b.fetch("path")),
            allowed: b.fetch("allowed", []),
          )
        end
      end
    end

    def self.build_known(config)
      result = Hash.new { |h, name| h[name] = Set.new }
      SECTIONS.each_key do |section|
        (config[section] || []).each do |b|
          (b["known_violations"] || []).each do |entry|
            result[b.fetch("name")] << [entry.fetch("file"), entry.fetch("constant")]
          end
        end
      end
      result
    end
  end
end
