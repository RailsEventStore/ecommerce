require "rails_event_store"
require "arkency/command_bus"

require_relative "../../lib/configuration"
require_relative "../../lib/transformations/refund_to_return_event_mapper"

Rails.configuration.to_prepare do
  mapper = RubyEventStore::Mappers::PipelineMapper.new(
    RubyEventStore::Mappers::Pipeline.new(
      Infra::EventStore.preserve_types,
      Transformations::RefundToReturnEventMapper.new(
        'Ordering::DraftRefundCreated' => 'Ordering::DraftReturnCreated',
        'Ordering::ItemAddedToRefund' => 'Ordering::ItemAddedToReturn',
        'Ordering::ItemRemovedFromRefund' => 'Ordering::ItemRemovedFromReturn'
      ),
      RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
      to_domain_event: RubyEventStore::Mappers::Transformation::DomainEvent.new
    )
  )

  Rails.configuration.event_store = Infra::EventStore.main(mapper: mapper)
  Rails.configuration.command_bus = Arkency::CommandBus.new

  Configuration.new.call(Rails.configuration.event_store, Rails.configuration.command_bus)
end