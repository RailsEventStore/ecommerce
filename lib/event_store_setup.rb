module EventStoreSetup
  def event_store
    @event_store ||= RailsEventStore::Client.new.tap do |es|
      es.subscribe(Denormalizers::OrderCreated.new, [Events::OrderCreated])
      es.subscribe(Denormalizers::OrderExpired.new, [Events::OrderExpired])
      es.subscribe(Denormalizers::ItemAddedToBasket.new, [Events::ItemAddedToBasket])
      es.subscribe(Denormalizers::ItemRemovedFromBasket.new, [Events::ItemRemovedFromBasket])
    end
  end
end
