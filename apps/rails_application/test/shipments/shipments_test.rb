require "test_helper"

module Shipments
  class ShipmentsTest < InMemoryTestCase
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

    def test_set_shipping_address
      order_id = SecureRandom.uuid

      shipping_address_added_to_shipment(order_id, "Line 1", "Line 2", "Line 3", "Line 4")

      shipment = Shipment.find_by(order_uid: order_id)

      assert_equal("Line 1", shipment.address_line_1)
      assert_equal("Line 2", shipment.address_line_2)
      assert_equal("Line 3", shipment.address_line_3)
      assert_equal("Line 4", shipment.address_line_4)
    end

    def test_update_shipping_address
      order_id = SecureRandom.uuid

      shipping_address_added_to_shipment(order_id, "Old 1", "Old 2", "Old 3", "Old 4")
      shipping_address_added_to_shipment(order_id, "New 1", "New 2", "New 3", "New 4")

      shipment = Shipment.find_by(order_uid: order_id)

      assert_equal("New 1", shipment.address_line_1)
      assert_equal("New 2", shipment.address_line_2)
      assert_equal("New 3", shipment.address_line_3)
      assert_equal("New 4", shipment.address_line_4)
    end

    def test_full_address
      order_id = SecureRandom.uuid

      shipping_address_added_to_shipment(order_id, "A", "B", "C", "D")

      shipment = Shipment.find_by(order_uid: order_id)

      assert_equal("A B C D", shipment.full_address)
    end

    def test_full_address_with_different_values
      order_id = SecureRandom.uuid

      shipping_address_added_to_shipment(order_id, "1", "2", "3", "4")

      shipment = Shipment.find_by(order_uid: order_id)

      assert_equal("1 2 3 4", shipment.full_address)
    end

    def test_assign_store_to_shipment
      order_id = SecureRandom.uuid
      store_id = SecureRandom.uuid

      shipment_registered(order_id, store_id)

      shipment = Shipment.find_by(order_uid: order_id)

      assert_equal(store_id, shipment.store_id)
    end

    def test_reassign_store_to_shipment
      order_id = SecureRandom.uuid
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid

      shipment_registered(order_id, store_id_1)
      shipment_registered(order_id, store_id_2)

      shipment = Shipment.find_by(order_uid: order_id)

      assert_equal(store_id_2, shipment.store_id)
    end

    def test_mark_order_placed
      order_id = SecureRandom.uuid

      order_registered(order_id, "2024/12/123")

      order = Order.find_by(uid: order_id)

      assert_equal(true, order.submitted)
    end

    def test_shipments_for_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      order_id_1 = SecureRandom.uuid
      order_id_2 = SecureRandom.uuid
      order_id_3 = SecureRandom.uuid

      offer_drafted(order_id_1)
      offer_drafted(order_id_2)
      offer_drafted(order_id_3)

      offer_registered_in_store(order_id_1, store_id_1)
      offer_registered_in_store(order_id_2, store_id_1)
      offer_registered_in_store(order_id_3, store_id_2)

      shipment_registered(order_id_1, store_id_1)
      shipment_registered(order_id_2, store_id_1)
      shipment_registered(order_id_3, store_id_2)

      order_registered(order_id_1, "2024/12/1")
      order_registered(order_id_2, "2024/12/2")
      order_registered(order_id_3, "2024/12/3")

      shipments = Shipments.shipments_for_store(store_id_1)

      assert_equal(2, shipments.count)
      assert_equal([order_id_1, order_id_2].sort, shipments.pluck(:order_uid).sort)
    end

    def test_find_shipment_in_store
      store_id = SecureRandom.uuid
      order_id = SecureRandom.uuid

      shipment_registered(order_id, store_id)

      shipment = Shipment.find_by(order_uid: order_id)

      found_shipment = Shipments.find_shipment_in_store(shipment.id, store_id)

      assert_equal(shipment.id, found_shipment.id)
    end

    def test_find_shipment_in_store_returns_nil_when_not_in_store
      store_id_1 = SecureRandom.uuid
      store_id_2 = SecureRandom.uuid
      order_id = SecureRandom.uuid

      shipment_registered(order_id, store_id_1)

      shipment = Shipment.find_by(order_uid: order_id)

      found_shipment = Shipments.find_shipment_in_store(shipment.id, store_id_2)

      assert_nil(found_shipment)
    end

    def test_with_full_address_scope
      order_id_1 = SecureRandom.uuid
      order_id_2 = SecureRandom.uuid
      product_id = SecureRandom.uuid
      prepare_product(product_id, "Test Product", 10)

      shipping_address_added_to_shipment(order_id_1, "Line 1", "Line 2", "Line 3", "Line 4")
      item_added_to_shipment_picking_list(order_id_2, product_id)

      shipments = Shipment.with_full_address

      assert_equal(1, shipments.count)
      assert_equal(order_id_1, shipments.first.order_uid)
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

    def shipping_address_added_to_shipment(order_id, line_1, line_2, line_3, line_4)
      event_store.publish(
        Shipping::ShippingAddressAddedToShipment.new(
          data: {
            order_id: order_id,
            postal_address: {
              line_1: line_1,
              line_2: line_2,
              line_3: line_3,
              line_4: line_4
            }
          }
        )
      )
    end

    def shipment_registered(order_id, store_id)
      event_store.publish(
        Stores::ShipmentRegistered.new(
          data: {
            shipment_id: order_id,
            store_id: store_id
          }
        )
      )
    end

    def order_registered(order_id, order_number)
      event_store.publish(
        Fulfillment::OrderRegistered.new(
          data: {
            order_id: order_id,
            order_number: order_number
          }
        )
      )
    end

    def offer_drafted(order_id)
      event_store.publish(
        Pricing::OfferDrafted.new(
          data: {
            order_id: order_id
          }
        )
      )
    end

    def offer_registered_in_store(order_id, store_id)
      event_store.publish(
        Stores::OfferRegistered.new(
          data: {
            order_id: order_id,
            store_id: store_id
          }
        )
      )
    end
  end
end
