Hanami.app.register_provider :event_store, namespace: true do
  prepare do
    require "ruby_event_store"
    require 'ruby_event_store/rom'

    repository = RubyEventStore::ROM::EventRepository.new(
      rom: target['persistence.rom'],
      serializer: RubyEventStore::NULL
    )

    client = RubyEventStore::Client.new(repository: repository)

    register "repository", repository
    register "client", client
  end
end
