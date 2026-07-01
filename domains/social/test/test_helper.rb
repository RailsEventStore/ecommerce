require "minitest/autorun" unless defined?(Mutant)
require "mutant/minitest/coverage"

require_relative "../lib/social"

module Social
  class Test < Infra::InMemoryTest
    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    private

    def assert_event_published(expected_event)
      actual_event = event_store.read.of_type(expected_event.class).last
      assert_equal(expected_event.data, actual_event.data)
      assert_equal(expected_event.class, actual_event.class)
    end
  end
end
