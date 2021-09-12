module TestPlumbing
  def self.with(event_store:, command_bus:)
    Module.new do
      include TestClassMethods

      define_method :before_setup do
        result = super()
        @command_bus = command_bus.call
        @event_store = event_store.call
        result
      end
    end
  end

  module TestClassMethods
    attr_reader :event_store, :command_bus

    def arrange(*commands)
      commands.each { |command| act(command) }
    end

    def act(command)
      command_bus.(command)
    end

    def assert_events(stream_name, *expected_events)
      scope = event_store.read.stream(stream_name)
      before = scope.last
      yield
      actual_events = before.nil? ? scope.to_a : scope.from(before.event_id).to_a
      to_compare = ->(ev) { { type: ev.event_type, data: ev.data } }
      assert_equal expected_events.map(&to_compare),
                   actual_events.map(&to_compare)
    end

    def assert_changes(actuals, expected)
      expects = expected.map(&:data)
      assert_equal(expects, actuals.map(&:data))
    end
  end
end
