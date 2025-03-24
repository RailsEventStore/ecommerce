require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/ordering"

module Ordering
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end
  end
end
