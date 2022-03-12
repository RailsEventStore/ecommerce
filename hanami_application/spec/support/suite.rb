# frozen_string_literal: true

require "dry/system/magic_comments_parser"
require "json"
require "pathname"
require "rspec"

module Test
  module SuiteHelpers
    module_function

    def suite
      @suite ||= RSpec.configuration.suite
    end
  end

  class Suite
    class << self
      def instance
        @instance ||= new
      end
    end

    SUITE_PATH = "spec/suite"

    attr_reader :root

    def initialize(application: nil, root: nil)
      @application = application
      @root = root ? Pathname(root) : Pathname(Dir.pwd).join(SUITE_PATH).freeze
    end

    def application
      @application ||= prepare_application
    end

    def prepare_application
      require_relative "../../config/application"
      @application = Hanami.prepare
    end

    def start_coverage
      return unless coverage?

      require "simplecov"

      SimpleCov.command_name(test_group_name) if parallel?

      SimpleCov.start do
        add_filter "/spec/"
        add_filter "/system/"
      end
    end

    def coverage_threshold
      ENV.fetch("COVERAGE_THRESHOLD").to_f.round
    end

    def current_coverage
      data = JSON.parse(File.open(application.root.join("coverage/.last_run.json")).read)
      data.fetch("result").fetch("covered_percent").to_f.round
    end

    def test_group_name
      @test_group_name ||= "test_suite_#{build_idx}"
    end

    def chdir(name)
      self.class.new(
        application: application,
        root: root.join(name.to_s)
      )
    end

    def files
      dirs.map { |dir| dir.join("**/*_spec.rb") }.flat_map { |path| Dir[path] }.sort
    end

    def groups
      dirs.map(&:basename).map(&:to_s).map(&:to_sym).sort
    end

    def dirs
      Dir[root.join("*")].map(&Kernel.method(:Pathname)).select(&:directory?)
    end

    def ci?
      !ENV["CI"].nil?
    end

    def parallel?
      ENV["CI_NODE_TOTAL"].to_i > 1
    end

    def build_idx
      ENV.fetch("CI_NODE_INDEX", -1).to_i
    end

    def coverage?
      ENV["COVERAGE"] == "true"
    end

    def log_dir
      Pathname(application.root).join("log")
    end

    def tmp_dir
      Pathname(application.root).join("tmp")
    end
  end
end

RSpec.configure do |config|
  ## Suite

  config.add_setting :suite
  config.suite = Test::Suite.new
  config.include Test::SuiteHelpers

  ## Derived metadata

  config.define_derived_metadata file_path: %r{/suite/} do |metadata|
    metadata[:group] = metadata[:file_path]
      .split("/")
      .then { |parts| parts[parts.index("suite") + 1] }
      .to_sym
  end

  # Add more derived metadata rules here, e.g.
  #
  # config.define_derived_metadata type: :request do |metadata|
  #   metadata[:db] = true
  #   metadata[:web] = true
  # end
  #
  # config.define_derived_metadata :db do |metadata|
  #   metadata[:factory] = true unless metadata.key?(:factory)
  # end

  ## Feature loading

  Dir[File.join(__dir__, "*.rb")].sort.each do |file|
    options = Dry::System::MagicCommentsParser.call(file)
    tag_name = options[:require_with_metadata]

    next unless tag_name

    tag_name = File.basename(file, File.extname(file)) if tag_name.eql?(true)

    config.when_first_matching_example_defined(tag_name.to_sym) do
      require file
    end
  end

  config.suite.groups.each do |group|
    config.when_first_matching_example_defined group: group do
      require_relative group.to_s
    rescue LoadError # rubocop:disable Lint/SuppressedException
    end
  end
end
