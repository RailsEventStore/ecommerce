require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/inventory"

module Inventory
  class Test < Infra::InMemoryTest
    cover "Inventory*"

    def before_setup
      super
      Configuration.new.call(event_store, command_bus)
    end

    def inventory_entry_stream(product_id)
      "Inventory::InventoryEntry$#{product_id}"
    end

    def reserve(product_id, quantity)
      Reserve.new(product_id: product_id, quantity: quantity)
    end

    def release(product_id, quantity)
      Release.new(product_id: product_id, quantity: quantity)
    end

    def dispatch(product_id, quantity)
      Dispatch.new(product_id: product_id, quantity: quantity)
    end

    def supply(product_id, quantity)
      Supply.new(product_id: product_id, quantity: quantity)
    end

    def cancel_reservation(order_id)
      Release.new(order_id: order_id)
    end
  end
end
