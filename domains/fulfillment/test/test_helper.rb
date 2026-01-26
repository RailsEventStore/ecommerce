require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/fulfillment"

module Fulfillment
  class Test < Infra::InMemoryTest
    def before_setup
      super
      generator = -> { FakeNumberGenerator.new }
      Configuration.new(generator).call(event_store, command_bus)
    end
  end
end
