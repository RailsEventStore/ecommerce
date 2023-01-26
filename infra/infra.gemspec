# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name = "infra"
  spec.version = "1.0.0"
  spec.authors = ["arkency"]
  spec.email = ["dev@arkency.com"]
  spec.require_paths = ["lib"]
  spec.files = Dir["lib/**/*"]
  spec.summary = "infrastructure for the application"

  spec.add_dependency "rake"
  spec.add_dependency "dry-struct"
  spec.add_dependency "dry-types"
  spec.add_dependency "aggregate_root", "~> 2.9.0"
  spec.add_dependency "arkency-command_bus"
  spec.add_dependency "ruby_event_store", "~> 2.9.0"
  spec.add_dependency "ruby_event_store-transformations"
  spec.add_dependency "sidekiq"
end
