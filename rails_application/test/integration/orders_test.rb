require "test_helper"

class OrdersTest < InMemoryRESIntegrationTestCase
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

    Sidekiq::Job.drain_all

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
    Sidekiq::Job.drain_all

    apply_discount_10_percent(order_id)
    Sidekiq::Job.drain_all

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }
    Sidekiq::Job.drain_all
    follow_redirect!
    assert_select("td", "$123.30")
    assert_select("dd", "Submitted")
    assert_select("dd", "Shopify")
    assert_select("td", "10.0%")
    get "/orders"
    post "/orders/#{order_id}/pay"
    Sidekiq::Job.drain_all
    follow_redirect!
    assert_select("td", text: "Paid")
    assert_payment_gateway_value(123.30)

    Shipments::MarkOrderSubmitted.drain

    verify_shipping(order_id)
    verify_invoice_generation(order_id)

    assert_res_browser_order_history
  end

  def test_expiring_orders
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    Sidekiq::Job.drain_all

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    Sidekiq::Job.drain_all
    get "/orders"
    assert_select("td", "Draft")
    post "/orders/expire"
    Sidekiq::Job.drain_all
    follow_redirect!
    assert_select("td", "Expired")
  end

  def test_cancel
    shopify_id = register_customer("Shopify")

    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    Sidekiq::Job.drain_all

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
    Sidekiq::Job.drain_all
    get "/orders/#{order_id}"
    assert_select("dd", "Cancelled")
  end

  def test_confirmed_order_doesnt_show_cancel_button
    shopify_id = register_customer("Shopify")

    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    Sidekiq::Job.drain_all

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
    post "/orders/#{order_id}/pay"
    Shipments::MarkOrderSubmitted.drain
    follow_redirect!
    assert_select("td", text: "Paid")
    get "/orders/#{order_id}"
    assert_select("button", 2)
  end

  def test_order_value_doesnt_change_after_changing_price
    shopify_id = register_customer("Shopify")

    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    Sidekiq::Job.drain_all

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }
    follow_redirect!
    Sidekiq::Job.drain_all
    get "/orders/#{order_id}"
    assert_select("td", text: "$39.00")
    assert_select("td", text: "$78.00")
    update_price(async_remote_id, 49)
    Sidekiq::Job.drain_all
    get "/orders/#{order_id}"

    assert_select("td", text: "$39.00")
    assert_select("td", text: "$78.00")
  end

  private

  def verify_shipping(order_id)
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
    Shipments::SetShippingAddress.drain
    follow_redirect!
    assert_select("dd", "Your shipment has been queued for processing.")
    get "/shipments"
    assert_select("td", "123 Main Street Apt 1 San Francisco US")
  end

  def verify_invoice_generation(order_id)
    get "/orders/#{order_id}"
    assert_select("a", "Add billing address")
    get "/orders/#{order_id}/billing_address/edit"
    assert_select("label", "Addressee's full name (Person or Company)")
    put "/orders/#{order_id}/billing_address", params: {
      "invoices_invoice" => {
        address_line_1: "44 Main Street",
        address_line_2: "Apt 2",
        address_line_3: "Francisco",
        address_line_4: "UK",
      }
    }
    follow_redirect!
    assert_select("button", "Issue now")
    post "/orders/#{order_id}/invoice"
    follow_redirect!

    assert_select("td", "Async Remote")
    assert_select("td", "$35.10")
    assert_select("td", "1")
    assert_select("td", "Fearless Refactoring")
    assert_select("td", "$44.10")
    assert_select("td", "2")
    assert_select("td", "$88.20")
    assert_select("td", "$123.30")

  end

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
