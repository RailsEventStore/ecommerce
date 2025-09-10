module Infra
  class EventStore < SimpleDelegator
    def self.main
      if ENV['DISABLE_EVENT_TRANSFORMATIONS'] == 'true'
        puts "[DEBUG] Event transformations DISABLED"
        mapper = debug_mapper
      else
        puts "[DEBUG] Event transformations ENABLED"
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
      end

      client = RailsEventStore::JSONClient.new(mapper: mapper)

      def client.publish(*events, **kwargs)
        events.each do |event|
          if event.respond_to?(:timestamp) && event.timestamp.nil?
            puts "[ERROR] Event #{event.class.name} has nil timestamp!"
            puts "[ERROR] Event ID: #{event.event_id}"
            puts "[ERROR] Stack trace:"
            puts caller[0..10].join("\n")
          end
        end
        super(*events, **kwargs)
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

    private

    def self.debug_mapper
      default_mapper_instance = default_mapper

      class << default_mapper_instance
        alias_method :original_event_to_record, :event_to_record

        def event_to_record(domain_event)
          record = original_event_to_record(domain_event)
          if record.timestamp.nil?
            puts "[ERROR] Record created with nil timestamp!"
            puts "[ERROR] Event class: #{domain_event.class.name}"
            puts "[ERROR] Event ID: #{domain_event.event_id}"
            puts "[ERROR] Domain event timestamp: #{domain_event.respond_to?(:timestamp) ? domain_event.timestamp : 'N/A'}"
            puts "[ERROR] Stack trace:"
            puts caller[0..15].join("\n")
          end
          record
        end
      end

      default_mapper_instance
    end

    def self.default_mapper
      RubyEventStore::Mappers::PipelineMapper.new(
        RubyEventStore::Mappers::Pipeline.new(
          RubyEventStore::Mappers::Transformation::DomainEvent.new,
          RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
          RubyEventStore::Mappers::Transformation::PreserveTypes.new
        )
      )
    end
  end
end
