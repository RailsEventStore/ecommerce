module Infra
  class EventStore < SimpleDelegator
    def self.main
      new(RailsEventStore::JSONClient.new(
        dispatcher: RubyEventStore::ComposedDispatcher.new(
          RailsEventStore::AfterCommitAsyncDispatcher.new(
            scheduler: RubyEventStore::SidekiqScheduler.new(serializer: RubyEventStore::Serializers::YAML)
          ),
          RubyEventStore::Dispatcher.new
        )))
    end

    def self.in_memory
      new(
        RubyEventStore::Client.new(
          repository: RubyEventStore::InMemoryRepository.new
        )
      )
    end

    def self.in_memory_rails
      new(
        RailsEventStore::Client.new(
          repository: RubyEventStore::InMemoryRepository.new
        )
      )
    end

    def subscribe(subscriber, to:)
      __getobj__.subscribe(subscriber, to: to)
    end

    def link_event_to_stream(event, stream, expected_version: :any)
      __getobj__.link(
        event.event_id,
        stream_name: stream,
        expected_version: expected_version
      )
    end
  end
end
