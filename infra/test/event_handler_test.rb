require_relative "test_helper"
require_relative "../lib/infra/event_handler"

module Infra
  class EventHandlerTest < InMemoryTest
    include ActiveJob::TestHelper

    def test_perform
      event_store.subscribe(DoFoo, to: [FooHappened])
      foo_happened = FooHappened.new

      event_store.publish(foo_happened)

      assert_nothing_raised { perform_enqueued_jobs(only: DoFoo) }
    end

    private
  end

  class DoFoo < EventHandler
    def call(event)
    end
  end

  class FooHappened < Event; end
end
