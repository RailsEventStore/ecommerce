Rails.application.config.event_store.tap do |es|
  es.subscribe(Denormalizers::OrderSubmitted, [Events::OrderSubmitted])
  es.subscribe(Denormalizers::OrderExpired, [Events::OrderExpired])
  es.subscribe(Denormalizers::ItemAddedToBasket, [Events::ItemAddedToBasket])
  es.subscribe(Denormalizers::ItemRemovedFromBasket, [Events::ItemRemovedFromBasket])
end
