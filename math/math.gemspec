# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "math"
  spec.version       = "1.0.0"
  spec.authors       = ["arkency"]
  spec.email         = ["dev@arkency.com"]
  spec.require_paths = ["lib"]
  spec.files         = Dir["lib/**/*"]
  spec.summary       = "math for the ecommerce bounded contexts"

  spec.add_dependency "rake"
end
