module Events
  class Base < RailsEventStore::Event
    def data
      super.symbolize_keys
    end
  end
  
  ItemAddedToBasket = Class.new(Base)
  ItemRemovedFromBasket = Class.new(Base)
  OrderSubmitted = Class.new(Base)
  OrderExpired = Class.new(Base)
end
