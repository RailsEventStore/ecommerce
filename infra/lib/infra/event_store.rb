module Infra
  class EventStore < SimpleDelegator
    def self.main
      require_relative "../../../rails_application/lib/transformations/refund_to_return_event_mapper" rescue nil

      begin
        mapper = RubyEventStore::Mappers::PipelineMapper.new(
          RubyEventStore::Mappers::Pipeline.new(
            preserve_types,
            Transformations::RefundToReturnEventMapper.new(
              'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
              'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
              'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
            ),
            RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
            to_domain_event: RubyEventStore::Mappers::Transformation::DomainEvent.new
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

    private

    def self.preserve_types
      preserve_types = RubyEventStore::Mappers::Transformation::PreserveTypes.new

      types_config = {
        Symbol => {
          serializer: ->(v) { v.to_s },
          deserializer: ->(v) { v.to_sym }
        },
        Time => {
          serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
          deserializer: ->(v) { Time.iso8601(v) }
        },
        Date => {
          serializer: ->(v) { v.iso8601 },
          deserializer: ->(v) { Date.iso8601(v) }
        },
        DateTime => {
          serializer: ->(v) { v.iso8601 },
          deserializer: ->(v) { DateTime.iso8601(v) }
        },
        BigDecimal => {
          serializer: ->(v) { v.to_s },
          deserializer: ->(v) { BigDecimal(v) }
        }
      }

      if defined?(ActiveSupport::TimeWithZone)
        types_config[ActiveSupport::TimeWithZone] = {
          serializer: ->(v) { v.iso8601(RubyEventStore::TIMESTAMP_PRECISION) },
          deserializer: ->(v) { Time.iso8601(v).in_time_zone },
          stored_type: ->(*) { "ActiveSupport::TimeWithZone" }
        }
      end

      if defined?(OpenStruct)
        types_config[OpenStruct] = {
          serializer: ->(v) { v.to_h },
          deserializer: ->(v) { OpenStruct.new(v) }
        }
      end

      types_config.each do |type, config|
        preserve_types.register(type, **config)
      end

      preserve_types
    end

  end
end
