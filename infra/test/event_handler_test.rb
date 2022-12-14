require_relative "test_helper"
require_relative "../lib/infra/event_handler"
require "active_support/testing/assertions"

module Infra
  class EventHandlerTest < InMemoryTest
    include ActiveSupport::Testing::Assertions
    def test_perform
      event_store.subscribe(DoFoo, to: [FooHappened])
      foo_happened = FooHappened.new

      event_store.publish(foo_happened)

      assert_nothing_raised { DoFoo.drain }
    end

    private
  end

  class DoFoo < EventHandler
    def call(event)
    end
  end

  class FooHappened < Event; end
end
