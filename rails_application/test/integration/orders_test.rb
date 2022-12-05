require "test_helper"

class OrdersTest < InMemoryRESIntegrationTestCase
  include ActiveJob::TestHelper
  cover "Orders*"

  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    Orders::Order.destroy_all
  end

  def test_submitting_empty_order
    arkency_id = register_customer("Arkency")

    get "/"
    assert_select "h1", "Orders"
    get "/orders/new"
    follow_redirect!
    assert_select "h1", "Order"
    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => SecureRandom.uuid,
           "customer_id" => arkency_id,
           "commit" => "Submit order"
         }
  end

  def test_happy_path
    shopify_id = register_customer("Shopify")

    order_id = SecureRandom.uuid
    another_order_id = SecureRandom.uuid

    async_remote_id = register_product("Async Remote", 39, 10)
    fearless_id     = register_product("Fearless Refactoring", 49, 10)

    perform_enqueued_jobs

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => another_order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    perform_enqueued_jobs

    apply_discount_10_percent(order_id)
    perform_enqueued_jobs

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }
    perform_enqueued_jobs
    follow_redirect!
    assert_select("td", "$123.30")
    assert_select("dd", "Submitted")
    assert_select("dd", "Shopify")
    assert_select("td", "10.0%")
    get "/orders"
    post "/orders/#{order_id}/pay"
    perform_enqueued_jobs
    follow_redirect!
    assert_select("td", text: "Paid")
    assert_payment_gateway_value(123.30)

    perform_enqueued_jobs(only: Shipments::MarkOrderSubmitted)

    get "/orders/#{order_id}"
    assert_select("dd", "Shipping address is missing.")
    assert_select("a", "Add shipment address")
    get "/orders/#{order_id}/shipping_address/edit"
    assert_select("label", "Addressee's full name (Person or Company)")
    put "/orders/#{order_id}/shipping_address", params: {
      "shipments_shipment" => {
        address_line_1: "123 Main Street",
        address_line_2: "Apt 1",
        address_line_3: "San Francisco",
        address_line_4: "US",
      }
    }
    perform_enqueued_jobs(only: Shipments::SetShippingAddress)
    follow_redirect!
    assert_select("dd", "Your shipment has been queued for processing.")
    get "/shipments"
    assert_select("td", "123 Main Street Apt 1 San Francisco US")

    assert_res_browser_order_history
  end

  def test_expiring_orders
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    perform_enqueued_jobs

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    perform_enqueued_jobs
    get "/orders"
    assert_select("td", "Draft")
    post "/orders/expire"
    perform_enqueued_jobs
    follow_redirect!
    assert_select("td", "Expired")
  end

  def test_cancel
    shopify_id = register_customer("Shopify")

    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    perform_enqueued_jobs

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    post "/orders/#{order_id}/cancel"
    perform_enqueued_jobs
    get "/orders/#{order_id}"
    assert_select("dd", "Cancelled")
  end

  private

  def assert_res_browser_order_history
    get "/res/api/streams/Orders%24all/relationships/events"
    event_names = JSON.load(body).fetch("data").map { |data| data.fetch("attributes").fetch("event_type") }

    assert(event_names.include?("Ordering::OrderConfirmed"))
    assert(event_names.include?("Ordering::ItemAddedToBasket"))
    assert(event_names.include?("Pricing::OrderTotalValueCalculated"))
    assert(event_names.include?("Ordering::OrderSubmitted"))
  end

  def assert_payment_gateway_value(value)
    assert_equal(
      1,
      Rails.configuration.payment_gateway.call.authorized_transactions.size
    )
    assert_equal(
      value,
      Rails.configuration.payment_gateway.call.authorized_transactions[0][1]
    )
  end

  def apply_discount_10_percent(order_id)
    get "/orders/#{order_id}/edit_discount"

    post "/orders/#{order_id}/update_discount?amount=10"
  end
end
