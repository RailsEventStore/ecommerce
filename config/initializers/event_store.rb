def instance_of(klass, *args)
  ->(event) { klass.new(*args).call(event) }
end

Rails.application.config.event_store.tap do |es|
  es.subscribe(instance_of(Denormalizers::OrderSubmitted), [Events::OrderSubmitted])
  es.subscribe(instance_of(Denormalizers::OrderExpired), [Events::OrderExpired])
  es.subscribe(instance_of(Denormalizers::ItemAddedToBasket), [Events::ItemAddedToBasket])
  es.subscribe(instance_of(Denormalizers::ItemRemovedFromBasket), [Events::ItemRemovedFromBasket])
end

AggregateRoot.configure do |config|
  config.default_event_store = Rails.application.config.event_store
end
