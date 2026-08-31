# frozen_string_literal: true

Hanami.app.register_provider :event_store do
  prepare do
    require "ecommerce"
    require "ruby_event_store/sequel"
    require "json"
  end

  start do
    target.start :db

    repository =
      RubyEventStore::Sequel::EventRepository.new(
        sequel: target["db.gateway"].connection,
        serializer: JSON
      )

    client =
      RubyEventStore::Client.new(
        repository: repository,
        mapper: Infra::EventStore.default_mapper
      )

    register "event_store", Infra::EventStore.new(client)
  end
end
