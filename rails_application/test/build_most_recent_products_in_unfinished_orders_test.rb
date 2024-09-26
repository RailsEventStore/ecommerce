# frozen_string_literal: true

require 'test_helper'

class BuildMostRecentProductsInUnfinishedOrdersTest < InMemoryTestCase
  def test_build
    product_1_id = 1
    product_2_id = 2
    product_3_id = 3
    event_store.publish(ProductCatalog::ProductCreated.new(data: { id: product_1_id, name: 'Product 1' }), stream_name: 'ProductCatalog::Product$1')
    event_store.publish(ProductCatalog::ProductCreated.new(data: { id: product_2_id, name: 'Product 2' }), stream_name: 'ProductCatalog::Product$2')
    event_store.publish(ProductCatalog::ProductCreated.new(data: { id: product_3_id, name: 'Product 3' }), stream_name: 'ProductCatalog::Product$3')

    order_1_id = 1
    order_2_id = 2

    event_store.publish(Ordering::OrderCreated.new(data: { id: order_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_1_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_1_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_1_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::OrderSubmitted.new(data: { id: order_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::OrderExpired.new(data: { id: order_1_id }), stream_name: "Ordering::Order$#{order_1_id}")

    event_store.publish(Ordering::OrderCreated.new(data: { id: order_2_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::ItemAdded.new(data: { order_id: order_2_id, product_id: product_1_id }), stream_name: "Ordering::Order$#{order_1_id}")
    event_store.publish(Ordering::OrderPaid.new(data: { id: order_2_id }), stream_name: "Ordering::Order$#{order_2_id}")


    MostRecentProductsInUnfinishedOrders.find_by(product_id: product_1_id).tap do |report|
      assert_equal 1, report.number_of_unfinished_orders
      assert_equal 3, report.number_of_items_in_unfinished_orders
      assert_equal [order_1_id], report.order_ids
    end
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
