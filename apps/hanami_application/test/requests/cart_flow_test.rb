# frozen_string_literal: true

require "test_helper"
require "minitest/mock"

class CartFlowTest < Hanami::Minitest::RequestTest
  test "buying multiple units of a product" do
    get "/"

    assert(last_response.ok?)
    assert_includes(last_response.body, "Domain-Driven Rails")
    assert_includes(last_response.body, "Your cart is empty.")

    product_id = first_product_id
    3.times do
      post "/cart/items", product_id: product_id, _csrf_token: csrf_token
      follow_redirect!
    end

    assert_includes(last_response.body, "added to cart")
    assert_includes(last_response.body, "Submit order")
    assert_includes(last_response.body, "<td>3</td>")

    post "/cart/submit", _csrf_token: csrf_token
    follow_redirect!

    assert_match(%r{Order \d{4}/\d{2}/\d+}, last_response.body)
    assert_includes(last_response.body, "Your order has been delivered.")
  end

  test "submitting an empty cart" do
    get "/"
    post "/cart/submit", _csrf_token: csrf_token
    follow_redirect!

    assert_includes(last_response.body, "Your cart is empty")
  end

  test "counting projected order items after additions and removals without reading events" do
    event_store = Hanami.app["event_store"]
    orders = Hanami.app["read_models.orders"]
    order_id = SecureRandom.uuid
    other_order_id = SecureRandom.uuid
    product_id = SecureRandom.uuid
    other_product_id = SecureRandom.uuid
    item = { order_id: order_id, product_id: product_id, price: 10 }
    other_item = { order_id: order_id, product_id: other_product_id, price: 20 }
    other_order_item = { order_id: other_order_id, product_id: product_id, price: 10 }

    event_store.stub(:read, ->(*) { flunk "Order queries must not read events" }) do
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))
      event_store.publish(Pricing::OfferDrafted.new(data: { order_id: other_order_id }))

      assert_equal(0, orders.item_count(order_id))
      assert_instance_of(Integer, orders.item_count(order_id))
      assert_equal(0, orders.item_count(SecureRandom.uuid))

      3.times { event_store.publish(Pricing::PriceItemAdded.new(data: item)) }
      event_store.publish(Pricing::PriceItemAdded.new(data: other_item))
      2.times { event_store.publish(Pricing::PriceItemAdded.new(data: other_order_item)) }

      assert_equal(4, orders.item_count(order_id))
      assert_equal(2, orders.item_count(other_order_id))

      event_store.publish(Pricing::PriceItemRemoved.new(data: item))

      assert_equal(3, orders.item_count(order_id))

      event_store.publish(Pricing::PriceItemRemoved.new(data: other_item))

      assert_equal(2, orders.item_count(order_id))

      2.times { event_store.publish(Pricing::PriceItemRemoved.new(data: item)) }

      assert_equal(0, orders.item_count(order_id))
      assert_equal(2, orders.item_count(other_order_id))
    end
  end

  private

  def first_product_id
    last_response.body[/option value="([0-9a-f-]{36})"/, 1]
  end

  def csrf_token
    last_response.body[/name="_csrf_token" value="([^"]+)"/, 1]
  end
end
