module Infra
  class ProcessManager
    include Infra::Retry

    class << self
      def subscribes_to(*events)
        @subscribed_events ||= []
        @subscribed_events += events
      end

      def subscribed_events
        @subscribed_events || []
      end
    end

    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(event)
      @state = initial_state
      @id = fetch_id(event)
      build_state(event)
      act
    end

    private

    attr_reader :event_store, :command_bus, :id, :state

    def build_state(event)
      with_retry do
        past_events = event_store.read.stream(stream_name).to_a
        last_stored = past_events.size - 1
        event_store.link(event.event_id, stream_name:, expected_version: last_stored)
        (past_events + [event]).each { |ev| @state = apply(ev) }
      end
    end

    def stream_name
      "#{self.class.name}$#{id}"
    end
  end
end
