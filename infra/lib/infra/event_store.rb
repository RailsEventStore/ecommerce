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
      new(RailsEventStore::Client.new(repository: repository, mapper: Mapper.new))
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

    def link_event_to_stream(event, stream, expected_version: :any)
      __getobj__.link(
        event.event_id,
        stream_name: stream,
        expected_version: expected_version
      )
    end
  end
end
