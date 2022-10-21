module Infra
  class Cqrs
    attr_reader :event_store

    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def subscribe(subscriber, events)
      @event_store.subscribe(subscriber, to: events)
    end

    def subscribe_to_all_events(handler)
      @event_store.subscribe_to_all_events(handler)
    end

    def register_command(command, command_handler)
      @command_bus.register(command, command_handler)
    end

    def run(command)
      @command_bus.call(command)
    end

    def link_event_to_stream(event, stream, expected_version = :any)
      @event_store.link(
        event.event_id,
        stream_name: stream,
        expected_version: :any
      )
    end

    def publish(event, stream_name)
      event_store.publish(event, stream_name: stream_name)
    end

    def all_events_from_stream(name)
      event_store.read.stream(name).to_a
    end

    def process(event_name, event_data_keys, command, command_data_keys)
      Process.new(@event_store, @command_bus).call(event_name, event_data_keys, command, command_data_keys)
    end
  end
end
