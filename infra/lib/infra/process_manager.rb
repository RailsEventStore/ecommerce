module Infra
  module ProcessManager
    module ProcessMethods
      def initialize(event_store, command_bus)
        @event_store = event_store
        @command_bus = command_bus
      end

      def call(event)
        build_state(event)
        act
      end

      private

      attr_reader :event_store, :command_bus

      def build_state(event)
        with_retry do
          stream = stream_name(event)
          past_events = event_store.read.stream(stream_name(event)).to_a
          last_stored = past_events.size - 1
          event_store.link(event.event_id, stream_name: stream, expected_version: last_stored)
          past_events.each { |ev| state.call(ev) }
          state.call(event)
        end
      end

      def stream_name(event)
        "#{self.class.name}$#{process_id(event)}"
      end
    end

    module Subscriptions
      def self.extended(host_class)
        host_class.instance_variable_set(:@subscribed_events, [])
      end

      def subscribes_to(*events)
        @subscribed_events += events
      end

      attr_reader :subscribed_events
    end

    def self.with_state(state_class)

      Module.new do
        define_method :state do
          @state ||= state_class.new
        end

        def self.included(host_class)
          host_class.include(ProcessMethods)
          host_class.include(Infra::Retry)
          host_class.extend(Subscriptions)
        end
      end
    end
  end
end
