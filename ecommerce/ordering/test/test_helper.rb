require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/ordering"

require_relative "../../pricing/lib/pricing"
require_relative "../../fulfillment/lib/fulfillment"

module Ordering
  class Test < Infra::InMemoryTest
    def before_setup
      generator = -> { Fulfillment::FakeNumberGenerator.new }
      super
      Configuration.new.call(event_store, command_bus)
      Pricing::Configuration.new.call(event_store, command_bus)
      Fulfillment::Configuration.new(generator).call(event_store, command_bus)
    end
  end
end
