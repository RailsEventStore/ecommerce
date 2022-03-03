require "minitest/autorun"
require "mutant/minitest/coverage"
require "active_support/isolated_execution_state"

require_relative "../lib/ordering"

module Ordering
  class Test < Infra::InMemoryTest
    def before_setup
      super
      number_generator = FakeNumberGenerator.new
      Configuration.new(-> { number_generator }).call(cqrs)
    end
  end
end
