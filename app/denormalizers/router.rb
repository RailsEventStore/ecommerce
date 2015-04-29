module Denormalizers
  class Router
    def handle_event(event)
      case event.event_type
      when 'OrderCreated' then Order.new.order_created(event)
      when 'OrderExpired' then Order.new.order_created(event)
      when 'ItemAddedToBasket'      then OrderLine.new.item_added_to_basket(event)
      when 'ItemRemovedFromBasket'  then OrderLine.new.item_removed_from_basket(event)
      end
    end
  end
end
