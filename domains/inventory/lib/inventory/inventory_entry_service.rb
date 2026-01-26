module Inventory
  class InventoryEntryService
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def supply(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.supply(command.quantity)
      end
    end

    def dispatch(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.dispatch(command.quantity)
      end
    end

    def reserve(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.reserve(command.quantity)
      end
    end

    def release(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.release(command.quantity)
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
