module Infra
  module TestPlumbing
    def self.with(event_store:, command_bus:)
      Module.new do
        include TestMethods

        define_method :before_setup do
          super()
          @command_bus = command_bus.call
          @event_store = event_store.call
        end
      end
    end

    def self.included(klass)
      klass.include TestPlumbing.with(
                      event_store: -> { EventStore.in_memory },
                      command_bus: -> { CommandBus.new }
                    )
    end

    module TestMethods
      attr_reader :event_store, :command_bus

      def arrange(*commands)
        commands.each { |command| act(command) }
      end

      def act(command)
        command_bus.(command)
      end
      alias run_command act

      def assert_events(stream_name, *expected_events)
        scope = event_store.read.stream(stream_name)
        before = scope.last
        yield
        actual_events =
          before.nil? ? scope.to_a : scope.from(before.event_id).to_a
        to_compare = ->(ev) { { type: ev.event_type, data: ev.data } }
        assert_equal expected_events.map(&to_compare),
                     actual_events.map(&to_compare)
      end

      def assert_events_contain(stream_name, *expected_events)
        scope = event_store.read.stream(stream_name)
        before = scope.last
        yield
        actual_events =
          before.nil? ? scope.to_a : scope.from(before.event_id).to_a
        to_compare = ->(ev) { { type: ev.event_type, data: ev.data } }
        expected_events.map(&to_compare).each do |expected|
          assert_includes(actual_events.map(&to_compare), expected)
        end
      end

      def assert_changes(actuals, expected)
        expects = expected.map(&:data)
        assert_equal(expects, actuals.map(&:data))
      end

      def assert_no_events(stream_name)
        scope = event_store.read.stream(stream_name)
        before = scope.last
        yield
        actual_events =
          before.nil? ? scope.to_a : scope.from(before.event_id).to_a
        assert_empty actual_events
      end

      def assert_published_within(
        event_type,
        event_data,
        event_store: @event_store,
        &block
      )
        before = event_store.read.to_a
        block.call
        events =
          (
            if before.any?
              event_store
                .read
                .newer_than(before.last.timestamp)
                .of_type(event_type)
                .to_a
            else
              event_store.read.of_type(event_type).to_a
            end
          )
        refute events.empty?, "expected some events, none were there"
        events.each do |e|
          assert_equal event_type.to_s, e.event_type
          assert_equal event_data.with_indifferent_access,
                       e.data.with_indifferent_access
        end
      end
    end
  end

  class InMemoryTest < Minitest::Test
    include TestPlumbing
  end
end
