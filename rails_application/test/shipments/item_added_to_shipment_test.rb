require "test_helper"

module Shipments
  class ItemAddedToShipmentTest < InMemoryTestCase
    cover "Shipments*"

    def test_add_new_item
      product_id = SecureRandom.uuid
      prepare_product(product_id, "Async Remote", 49)

      order_id = SecureRandom.uuid
      item_added_to_shipment_picking_list(order_id, product_id)

      assert_equal(1, ShipmentItem.count)

      shipment_item = Shipment.find_by(order_uid: order_id).shipment_items.first

      assert_equal(product_id, shipment_item.product_id)
      assert_equal("Async Remote", shipment_item.product_name)
      assert_equal(1, shipment_item.quantity)
    end

    def test_add_the_same_item_twice
      product_id = SecureRandom.uuid
      prepare_product(product_id, "Async Remote", 49)

      order_id = SecureRandom.uuid
      item_added_to_shipment_picking_list(order_id, product_id)
      item_added_to_shipment_picking_list(order_id, product_id)

      assert_equal(1, ShipmentItem.count)

      shipment_item = Shipment.find_by(order_uid: order_id).shipment_items.first

      assert_equal(product_id, shipment_item.product_id)
      assert_equal("Async Remote", shipment_item.product_name)
      assert_equal(2, shipment_item.quantity)
    end

    def test_add_another_item
      product_id = SecureRandom.uuid
      prepare_product(product_id, "Async Remote", 49)

      another_product_id = SecureRandom.uuid
      prepare_product(another_product_id, "Fearless Refactoring", 39)

      order_id = SecureRandom.uuid
      item_added_to_shipment_picking_list(order_id, product_id)
      item_added_to_shipment_picking_list(order_id, another_product_id)

      shipment = Shipment.find_by(order_uid: order_id)

      assert_equal(2, shipment.shipment_items.count)

      shipment_item_1 = shipment.shipment_items.find_by(product_id: product_id)
      assert_equal("Async Remote", shipment_item_1.product_name)
      assert_equal(1, shipment_item_1.quantity)

      shipment_item_2 = shipment.shipment_items.find_by(product_id: another_product_id)
      assert_equal("Fearless Refactoring", shipment_item_2.product_name)
      assert_equal(1, shipment_item_2.quantity)
    end

    private

    def event_store
      Rails.configuration.event_store
    end

    def prepare_product(product_id, name, price)
      event_store.publish(
        ProductCatalog::ProductRegistered.new(
          data: {
            product_id: product_id
          }
        )
      )
      event_store.publish(
        ProductCatalog::ProductNamed.new(
          data: {
            product_id: product_id,
            name: name
          }
        )
      )
      event_store.publish(
        Pricing::PriceSet.new(
          data: {
            product_id: product_id,
            price: price
          }
        )
      )
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
  end
end
