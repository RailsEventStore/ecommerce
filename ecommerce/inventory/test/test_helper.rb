require "minitest/autorun"
require "mutant/minitest/coverage"

require_relative "../lib/inventory"
require_relative "../../ordering/lib/ordering"
require_relative "../../configuration"

module Inventory
  class Test < Infra::InMemoryTest
    cover "Inventory*"

    def before_setup
      super
      ecommerce_configuration = Ecommerce::Configuration.new
      [
        Configuration.new,
        ecommerce_configuration.public_method(:check_product_availability_on_adding_item_to_basket),
        ecommerce_configuration.public_method(:enable_inventory_sync_from_ordering)
      ].each { |c| c.call(cqrs) }
    end

    def inventory_entry_stream(product_id)
      "Inventory::InventoryEntry$#{product_id}"
    end

    def reservation_stream(order_id)
      "Inventory::Reservation$#{order_id}"
    end

    def supply(product_id, quantity)
      Supply.new(product_id: product_id, quantity: quantity)
    end

    def submit_reservation(order_id, uuid_quantity_hash = {})
      SubmitReservation.new(order_id: order_id, reservation_items: uuid_quantity_hash)
    end

    def cancel_reservation(order_id)
      CancelReservation.new(order_id: order_id)
    end

    def complete_reservation(order_id)
      CompleteReservation.new(order_id: order_id)
    end
  end
end
