require "aggregate_root"
require "active_support/notifications"

module Inventory
  class CheckAvailabilityOnOrderItemAddedToBasket
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(event)
      product_id = event.data.fetch(:product_id)
      quantity = event.data.fetch(:quantity_before) + 1
      with_inventory_entry(product_id) do |entry|
        entry.check_availability(quantity)
      rescue InventoryEntry::StockLevelUndefined
        # that's ok for now
      end
    end

    private

    def with_inventory_entry(product_id)
      @repository.with_aggregate(InventoryEntry, product_id) do |entry|
        yield(entry)
      end
    end
  end
end