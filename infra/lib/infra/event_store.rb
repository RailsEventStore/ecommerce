module Infra
  class Mapper < RubyEventStore::Mappers::PipelineMapper
    def initialize
      super(
        RubyEventStore::Mappers::Pipeline.new(
          RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
          RubyEventStore::Transformations::WithIndifferentAccess.new
        )
      )
    end
  end

  class EventStore < SimpleDelegator

    def self.main
      repository = RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
      new(RailsEventStore::Client.new(
        repository: repository, mapper: Mapper.new,
        dispatcher:
          RubyEventStore::ComposedDispatcher.new(
            RailsEventStore::AfterCommitAsyncDispatcher.new(scheduler: RubyEventStore::SidekiqScheduler.new(serializer: RubyEventStore::NULL)),
            RubyEventStore::Dispatcher.new
          )

      ))
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
