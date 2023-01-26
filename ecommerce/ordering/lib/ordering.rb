require "infra"
require_relative "ordering/events/item_added_to_basket"
require_relative "ordering/events/item_removed_from_basket"
require_relative "ordering/events/order_submitted"
require_relative "ordering/events/order_expired"
require_relative "ordering/events/order_confirmed"
require_relative "ordering/events/order_cancelled"
require_relative "ordering/events/order_pre_submitted"
require_relative "ordering/events/order_rejected"
require_relative "ordering/commands/add_item_to_basket"
require_relative "ordering/commands/remove_item_from_basket"
require_relative "ordering/commands/submit_order"
require_relative "ordering/commands/set_order_as_expired"
require_relative "ordering/commands/confirm_order"
require_relative "ordering/commands/cancel_order"
require_relative "ordering/commands/accept_order"
require_relative "ordering/commands/reject_order"
require_relative "ordering/fake_number_generator"
require_relative "ordering/number_generator"
require_relative "ordering/service"
require_relative "ordering/order"

module Ordering
  class Configuration
    def initialize(number_generator)
      @number_generator = number_generator
    end

    def call(event_store, command_bus)
      command_bus.register(
        SubmitOrder,
        OnSubmitOrder.new(event_store, @number_generator.call)
      )
      command_bus.register(AddItemToBasket, OnAddItemToBasket.new(event_store))
      command_bus.register(RemoveItemFromBasket, OnRemoveItemFromBasket.new(event_store))
      command_bus.register(SetOrderAsExpired, OnSetOrderAsExpired.new(event_store))
      command_bus.register(ConfirmOrder, OnConfirmOrder.new(event_store))
      command_bus.register(CancelOrder, OnCancelOrder.new(event_store))
      command_bus.register(AcceptOrder, OnAcceptOrder.new(event_store))
      command_bus.register(RejectOrder, OnRejectOrder.new(event_store))
    end
  end
end
