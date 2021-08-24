module Inventory
  class InventoryEntryService
    include CommandHandler

    def call(command)
      send command.class.name.demodulize.underscore, command
    end

    private

    def supply(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.supply(command.quantity)
      end
    end

    def dispatch(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.release(command.quantity)
        entry.dispatch(command.quantity)
      end
    end

    def reserve_stock(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.reserve(command.quantity)
      end
    end

    def release_stock(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.release(command.quantity)
      end
    end

    def check_availability(command)
      with_inventory_entry(command.product_id) do |entry|
        entry.check_availability(command.quantity)
      end
    end

    def with_inventory_entry(product_id)
      with_aggregate(InventoryEntry, product_id) do |entry|
        yield(entry)
      end
    end
  end
end