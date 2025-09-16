module Infra
  class EventStore < SimpleDelegator
    def self.main
      require_relative "../../../rails_application/lib/transformations/refund_to_return_event_mapper" rescue nil

      begin
        mapper = RubyEventStore::Mappers::PipelineMapper.new(
          RubyEventStore::Mappers::Pipeline.new(
            Transformations::RefundToReturnEventMapper.new(
              'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
              'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
              'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
            ),
            RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
            RubyEventStore::Mappers::Transformation::PreserveTypes.new
          )
        )
        client = RailsEventStore::JSONClient.new(mapper: mapper)
      rescue => e
        puts "Mapper creation failed: #{e.message}"
        client = RailsEventStore::JSONClient.new
      end

      new(client)
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
