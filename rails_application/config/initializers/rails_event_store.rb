require "rails_event_store"
require "arkency/command_bus"

require_relative "../../lib/configuration"

module Ecommerce
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

  Rails.configuration.to_prepare do
    repository =
      RailsEventStoreActiveRecord::EventRepository.new(
        serializer: RubyEventStore::NULL
      )
    Rails.configuration.event_store =
      RailsEventStore::Client.new(repository: repository, mapper: Mapper.new)
    Rails.configuration.command_bus = Arkency::CommandBus.new

    cqrs = Infra::Cqrs.new(Rails.configuration.event_store, Rails.configuration.command_bus)
    Configuration.new.call(cqrs)
  end
end