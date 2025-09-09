module Infra
  class EventStore < SimpleDelegator
    def self.main
      require_relative "../../../rails_application/lib/transformations/refund_to_return_event_mapper" rescue nil

      if defined?(Transformations::RefundToReturnEventMapper)
        mapper = RubyEventStore::Mappers::PipelineMapper.new(
          RubyEventStore::Mappers::Pipeline.new(
            Transformations::RefundToReturnEventMapper.new(
              'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
              'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
              'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
            ),
            RubyEventStore::Mappers::Transformation::DomainEvent.new,
            RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
            RubyEventStore::Mappers::Transformation::PreserveTypes.new
          )
        )
      else
        mapper = default_mapper
      end

      new(RailsEventStore::JSONClient.new(mapper: mapper))
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

    private

    def self.default_mapper
      RubyEventStore::Mappers::PipelineMapper.new(
        RubyEventStore::Mappers::Pipeline.new(
          RubyEventStore::Mappers::Transformation::DomainEvent.new,
          RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new
        )
      )
    end
  end
end
