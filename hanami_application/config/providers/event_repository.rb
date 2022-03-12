# frozen_string_literal: true

Hanami.application.register_provider :event_repository do |container|
  start do
    # Command bus registration
    repository = Proc.new {}
      # RailsEventStoreActiveRecord::EventRepository.new(
      #   serializer: RubyEventStore::NULL
      # )
    register "event_repository", repository
  end
end
