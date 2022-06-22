# frozen_string_literal: true

Hanami.application.register_provider :event_repository do |container|
  start do
    require 'ruby_event_store/rom'
    repository =
      RubyEventStore::ROM::EventRepository.new(
        rom: container['persistence.rom'],
        serializer: JSON
      )
    register "event_repository", repository
  end
end
