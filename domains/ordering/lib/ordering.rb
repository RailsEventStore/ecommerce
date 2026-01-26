require "infra"
require_relative "ordering/events/draft_return_created"
require_relative "ordering/events/item_added_to_return"
require_relative "ordering/events/item_removed_from_return"
require_relative "ordering/commands/create_draft_return"
require_relative "ordering/commands/add_item_to_return"
require_relative "ordering/commands/remove_item_from_return"
require_relative "ordering/service"
require_relative "ordering/return"
require_relative "ordering/returnable_products"

module Ordering
  class Configuration
    def call(event_store, command_bus)
      command_bus.register(CreateDraftRefund, OnCreateDraftRefund.new(event_store))
      command_bus.register(AddItemToRefund, OnAddItemToRefund.new(event_store))
      command_bus.register(RemoveItemFromRefund, OnRemoveItemFromRefund.new(event_store))
    end
  end
end
