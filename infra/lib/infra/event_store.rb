module Infra
  class Mapper < RubyEventStore::Mappers::PipelineMapper
    def initialize
      super(
        RubyEventStore::Mappers::Pipeline.new(
          RubyEventStore::Mappers::Transformation::PreserveTypes
            .new
            .register(Symbol, serializer: ->(v) { v.to_s }, deserializer: ->(v) { v.to_sym })
            .register(
              Time,
              serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
              deserializer: ->(v) { Time.iso8601(v) }
            )
            .register(
              ActiveSupport::TimeWithZone,
              serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
              deserializer: ->(v) { Time.iso8601(v).in_time_zone },
              stored_type: ->(*) { "ActiveSupport::TimeWithZone" }
            )
            .register(Date, serializer: ->(v) { v.iso8601 }, deserializer: ->(v) { Date.iso8601(v) })
            .register(DateTime, serializer: ->(v) { v.iso8601 }, deserializer: ->(v) { DateTime.iso8601(v) })
            .register(BigDecimal, serializer: ->(v) { v.to_s }, deserializer: ->(v) { BigDecimal(v) }),
          RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
          RubyEventStore::Transformations::WithIndifferentAccess.new
        )
      )
    end
  end

  class EventStore < SimpleDelegator

    def self.main
      new(RailsEventStore::JSONClient.new(
        mapper: Mapper.new,
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
