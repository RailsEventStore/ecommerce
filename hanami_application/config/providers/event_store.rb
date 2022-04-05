# frozen_string_literal: true

Hanami.application.register_provider :event_store do |container|
  start do
    require "ruby_event_store"

    event_store =
      RubyEventStore::Client.new(
        repository: container['event_repository'],
        mapper: container['event_store_mapper']
      )
    register 'event_store', event_store
  end
end
