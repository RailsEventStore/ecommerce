module Denormalizers
  class Router
    def handle_event(event)
      case event.event_type
      when Events::OrderCreated.name then Denormalizers::Order.new.order_created(event)
      when Events::OrderExpired.name then Denormalizers::Order.new.order_created(event)
      when Events::ItemAddedToBasket.name      then Denormalizers::OrderLine.new.item_added_to_basket(event)
      when Events::ItemRemovedFromBasket.name  then Denormalizers::OrderLine.new.item_removed_from_basket(event)
      end
    end
  end
end
