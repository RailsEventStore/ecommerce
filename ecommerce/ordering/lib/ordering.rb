require "infra"
require_relative "ordering/events/item_added_to_basket"
require_relative "ordering/events/item_removed_from_basket"
require_relative "ordering/events/order_placed"
require_relative "ordering/events/order_expired"
require_relative "ordering/events/order_submitted"
require_relative "ordering/events/order_rejected"
require_relative "ordering/events/draft_refund_created"
require_relative "ordering/events/item_added_to_refund"
require_relative "ordering/events/item_removed_from_refund"
require_relative "ordering/commands/add_item_to_basket"
require_relative "ordering/commands/remove_item_from_basket"
require_relative "ordering/commands/submit_order"
require_relative "ordering/commands/set_order_as_expired"
require_relative "ordering/commands/accept_order"
require_relative "ordering/commands/reject_order"
require_relative "ordering/commands/create_draft_refund"
require_relative "ordering/commands/add_item_to_refund"
require_relative "ordering/commands/remove_item_from_refund"
require_relative "ordering/fake_number_generator"
require_relative "ordering/number_generator"
require_relative "ordering/service"
require_relative "ordering/order"
require_relative "ordering/refund"
require_relative "ordering/projections"

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
      command_bus.register(AcceptOrder, OnAcceptOrder.new(event_store))
      command_bus.register(RejectOrder, OnRejectOrder.new(event_store))
      command_bus.register(CreateDraftRefund, OnCreateDraftRefund.new(event_store))
      command_bus.register(AddItemToRefund, OnAddItemToRefund.new(event_store))
      command_bus.register(RemoveItemFromRefund, OnRemoveItemFromRefund.new(event_store))
    end
  end
end
