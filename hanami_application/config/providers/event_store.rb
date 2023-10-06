Hanami.app.register_provider :event_store, namespace: true do
  prepare do
    require "ruby_event_store"
    require 'ruby_event_store/rom'

    rom_config = target["persistence.config"]
    rom_config.register_mapper   RubyEventStore::ROM::Mappers::StreamEntryToSerializedRecord
    rom_config.register_mapper   RubyEventStore::ROM::Mappers::EventToSerializedRecord

    rom_config.register_relation RubyEventStore::ROM::Relations::Events
    rom_config.register_relation RubyEventStore::ROM::Relations::StreamEntries

    repository = RubyEventStore::ROM::EventRepository.new(
      rom: ROM.container(rom_config),
      serializer: JSON
    )

    client = RubyEventStore::Client.new(repository: repository)

    register "repository", repository
    register "client", client
  end
end
