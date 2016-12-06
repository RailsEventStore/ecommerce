module CommandHandlers
  class FakeNumberGenerator
    def call
      "123/08/2015"
    end
  end

  module TestCase
    include Command::Execute

    def arrange(stream,  events)
      events.each{|e| event_store.publish_event(e, stream_name: stream)}
    end

    def act(stream, command)
      before = event_store.read_stream_events_forward(stream)
      execute(command)
      after = event_store.read_stream_events_forward(stream)
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

    private
    def dependencies
      {
        number_generator: FakeNumberGenerator.new
      }
    end
  end
end
