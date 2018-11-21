module CommandHandlers
  class FakeNumberGenerator
    def call
      "123/08/2015"
    end
  end

  module TestCase
    def arrange(stream,  events)
      events.each{|e| event_store.publish(e, stream_name: stream)}
    end

    def act(stream, command)
      before = event_store.read.stream(stream).each.to_a
      command_bus.(command)
      after = event_store.read.stream(stream).each.to_a
      after.reject{|a| before.any?{|b| a.event_id == b.event_id}}
    end

    def assert_changes(actuals, expected)
      expects = expected.map(&:data)
      assert_equal(actuals.map(&:data), expects)
    end

    def assert_no_changes(actuals)
      assert_empty(actuals)
    end

    def event_store
      Rails.application.config.event_store
    end

    def command_bus
      Rails.configuration.command_bus
    end

    private
    def dependencies
      {
        number_generator: FakeNumberGenerator.new
      }
    end
  end
end
