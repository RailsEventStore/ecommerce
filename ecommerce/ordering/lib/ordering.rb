require "infra"
require_relative "ordering/events/item_added_to_basket"
require_relative "ordering/events/item_removed_from_basket"
require_relative "ordering/events/order_submitted"
require_relative "ordering/events/order_expired"
require_relative "ordering/events/order_paid"
require_relative "ordering/events/order_cancelled"
require_relative "ordering/commands/add_item_to_basket"
require_relative "ordering/commands/remove_item_from_basket"
require_relative "ordering/commands/submit_order"
require_relative "ordering/commands/set_order_as_expired"
require_relative "ordering/commands/mark_order_as_paid"
require_relative "ordering/commands/cancel_order"
require_relative "ordering/fake_number_generator"
require_relative "ordering/number_generator"
require_relative "ordering/service"
require_relative "ordering/order"
require_relative "ordering/order_line"

module Ordering
  class Configuration
    def initialize(number_generator)
      @number_generator = number_generator
    end

    def call(cqrs)
      cqrs.register(
        SubmitOrder,
        OnSubmitOrder.new(cqrs.event_store, @number_generator.call)
      )
      cqrs.register(AddItemToBasket, OnAddItemToBasket.new(cqrs.event_store))
      cqrs.register(RemoveItemFromBasket, OnRemoveItemFromBasket.new(cqrs.event_store))
      cqrs.register(SetOrderAsExpired, OnSetOrderAsExpired.new(cqrs.event_store))
      cqrs.register(MarkOrderAsPaid, OnMarkOrderAsPaid.new(cqrs.event_store))
      cqrs.register(CancelOrder, OnCancelOrder.new(cqrs.event_store))
    end
  end
end
