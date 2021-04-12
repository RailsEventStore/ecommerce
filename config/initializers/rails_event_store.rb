require 'rails_event_store'
require 'arkency/command_bus'

Rails.configuration.to_prepare do
  repository =
    RailsEventStoreActiveRecord::EventRepository.new(serializer: RubyEventStore::NULL)
  Rails.configuration.event_store =
    RailsEventStore::Client.new(repository: repository)

  # Subscribe event handlers below
  Rails.configuration.event_store.tap do |store|
    # store.subscribe(InvoiceReadModel.new, to: [InvoicePrinted])
    # store.subscribe(lambda { |event| SendOrderConfirmation.new.call(event) }, to: [OrderSubmitted])
    # store.subscribe_to_all_events(lambda { |event| Rails.logger.info(event.event_type) })

    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
  end

  Rails.configuration.command_bus =
    Arkency::CommandBus.new
  Configuration.new.call(
    Rails.configuration.event_store,
    Rails.configuration.command_bus
  )
end
