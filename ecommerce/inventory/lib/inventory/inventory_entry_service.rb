module Inventory
  class InventoryEntryService
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(command)
      __send__(command.class.name.demodulize.underscore, command)
    end

    private

    def supply(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.supply(command.quantity)
      end
    end

    def with_inventory_entry(product_id)
      @repository.with_aggregate(InventoryEntry, product_id) do |entry|
        yield(entry)
      end
    end
  end
end