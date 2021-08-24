module Inventory
  class ReservationService
    include CommandHandler

    def call(command)
      send command.class.name.demodulize.underscore, command
    end

    private

    def adjust_reservation(command)
      with_reservation(command.order_id) do |reservation|
        reservation.adjust(command.product_id, command.quantity)
      end
    end

    def submit_reservation(command)
      with_reservation(command.order_id) do |reservation|
        reserved_items = []
        reservation.reservation_items.map do |item|
          with_inventory_entry(item.product_id) do |entry|
            entry.reserve(item.quantity)
          rescue InventoryEntry::StockLevelUndefined
          else
            reserved_items << item
          end
        end
        reservation.submit reserved_items
      end
    end

    def complete_reservation(command)
      with_reservation(command.order_id) do |reservation|
        reservation.reservation_items.each do |item|
          with_inventory_entry(item.product_id) do |entry|
            entry.release(item.quantity)
            entry.dispatch(item.quantity)
          end
        end
        reservation.complete
      end
    end

    def cancel_reservation(command)
      with_reservation(command.order_id) do |reservation|
        reservation.reservation_items.each do |item|
          with_inventory_entry(item.product_id) do |entry|
            entry.release(item.quantity)
          end
        end
        reservation.cancel
      end
    end

    def with_reservation(order_id)
      with_aggregate(Reservation, order_id) do |reservation|
        yield(reservation)
      end
    end

    def with_inventory_entry(product_id)
      with_aggregate(InventoryEntry, product_id) do |entry|
        yield(entry)
      end
    end
  end
end