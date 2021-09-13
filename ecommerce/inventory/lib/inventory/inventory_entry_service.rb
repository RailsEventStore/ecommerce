module Inventory
  class InventoryEntryService
    include Infra::CommandHandler

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
      with_aggregate(InventoryEntry, product_id) do |entry|
        yield(entry)
      end
    end
  end
end