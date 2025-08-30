# # frozen_string_literal: true

Hanami.application.register_provider :event_store_mapper do |container|
  start do
    require "ruby_event_store"
    require "ruby_event_store/transformations"

    mapper = RubyEventStore::Mappers::PipelineMapper.new(
      RubyEventStore::Mappers::Pipeline.new(
        RubyEventStore::Mappers::Transformation::SymbolizeMetadataKeys.new,
        RubyEventStore::Transformations::WithIndifferentAccess.new
      )
    )
    register 'event_store_mapper', mapper
  end
end
