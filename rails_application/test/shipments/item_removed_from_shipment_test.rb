require "test_helper"

module Shipments
  class ItemRemovedFromShipmentTest < InMemoryTestCase
    cover "Shipments*"

    def test_remove_item_when_quantity_is_greater_than_1
      product_id = SecureRandom.uuid
      prepare_product(product_id, "Async Remote", 49)

      order_id = SecureRandom.uuid
      item_added_to_shipment_picking_list(order_id, product_id)
      item_added_to_shipment_picking_list(order_id, product_id)
      item_removed_from_shipment_picking_list(order_id, product_id)
      assert_equal(1, ShipmentItem.count)

      shipment_item = Shipment.find_by(order_uid: order_id).shipment_items.first

      assert_equal(shipment_item.product_id, product_id)
      assert_equal("Async Remote", shipment_item.product_name)
      assert_equal(1, shipment_item.quantity)
    end

    def test_remove_item_when_quantity_eq_1
      product_id = SecureRandom.uuid
      prepare_product(product_id, "Async Remote", 49)

      order_id = SecureRandom.uuid
      item_added_to_shipment_picking_list(order_id, product_id)
      item_removed_from_shipment_picking_list(order_id, product_id)
      assert_equal(0, ShipmentItem.count)
    end

    def test_remove_item_when_there_is_another_item
      product_id = SecureRandom.uuid
      prepare_product(product_id, "Async Remote", 49)

      another_product_id = SecureRandom.uuid
      prepare_product(another_product_id, "Fearless Refactoring", 39)

      order_id = SecureRandom.uuid
      item_added_to_shipment_picking_list(order_id, product_id)
      item_added_to_shipment_picking_list(order_id, product_id)
      item_added_to_shipment_picking_list(order_id, another_product_id)
      item_removed_from_shipment_picking_list(order_id, another_product_id)

      assert_equal(1, ShipmentItem.count)

      shipment_item = Shipment.find_by(order_uid: order_id).shipment_items.first

      assert_equal(product_id, shipment_item.product_id)
      assert_equal("Async Remote", shipment_item.product_name)
      assert_equal(2, shipment_item.quantity)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id, name, price)
      run_command(
        ProductCatalog::RegisterProduct.new(
          product_id: product_id,
        )
      )
      run_command(
        ProductCatalog::NameProduct.new(
          product_id: product_id,
          name: name
        )
      )
      run_command(Pricing::SetPrice.new(product_id: product_id, price: price))
    end

    def item_added_to_shipment_picking_list(order_id, product_id)
      event_store.publish(
        Shipping::ItemAddedToShipmentPickingList.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      )
    end

    def item_removed_from_shipment_picking_list(order_id, product_id)
      event_store.publish(
        Shipping::ItemRemovedFromShipmentPickingList.new(
          data: {
            order_id: order_id,
            product_id: product_id
          }
        )
      )
    end
  end
end
