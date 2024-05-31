# frozen_string_literal: true

begin
  require "rspec"
  require "rspec/core/rake_task"

  require_relative "suite"
  suite = Test::Suite.instance

  desc "Run all specs"
  RSpec::Core::RakeTask.new :spec do |t|
    opts = ["#{suite.root} --pattern **/*_spec.rb"]

    if suite.ci?
      # Add custom output/formatting here for CI tool to pick up...
      opts << "--format progress"
    end

    t.rspec_opts = opts.join(" ")
  end

  namespace :spec do
    suite.groups.each do |group|
      desc "Run #{group} specs"
      RSpec::Core::RakeTask.new(group) do |t|
        t.rspec_opts = "#{suite.chdir(group).root} --pattern **/*_spec.rb"
      end
    end

    desc "Verify coverage"
    task :verify_coverage do
      if suite.current_coverage.to_i < suite.coverage_threshold
        puts "Coverage too low. Current: #{suite.current_coverage}%; Expected min: #{suite.coverage_threshold}%"
        exit 1
      end
    end
  end

  task default: [:spec]
rescue LoadError
end
