require 'rails_event_store'
require 'arkency/command_bus'


Rails.configuration.to_prepare do
  repository =
    RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
  Rails.configuration.event_store =
    RailsEventStore::Client.new(repository: repository)
  Rails.configuration.command_bus =
    Arkency::CommandBus.new
  Configuration.new.call(
    Rails.configuration.event_store,
    Rails.configuration.command_bus
  )
end
