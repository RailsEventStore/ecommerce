module Events
  ItemAddedToBasket = Class.new(RailsEventStore::Event)
  ItemRemovedFromBasket = Class.new(RailsEventStore::Event)
  OrderCreated = Class.new(RailsEventStore::Event)
  OrderExpired = Class.new(RailsEventStore::Event)
end
