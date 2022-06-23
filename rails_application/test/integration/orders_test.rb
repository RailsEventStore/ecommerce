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
    assert_select "h1", "New Order"
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
    follow_redirect!
    assert_select("td", "$39.00")
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    follow_redirect!
    assert_select("td", "$88.00")
    post "/orders/#{order_id}/add_item?product_id=#{fearless_id}"
    follow_redirect!
    assert_select("td", "$137.00")

    apply_discount_10_percent(order_id)

    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }
    follow_redirect!
    assert_select("td", "$123.30")
    assert_select("dd", "Submitted")
    assert_select("dd", "Shopify")
    assert_select("td", "10.0%")
    get "/orders"
    post "/orders/#{order_id}/pay"
    follow_redirect!
    assert_select("td", text: "Paid")
    assert_payment_gateway_value(123.30)
    assert_res_browser_order_history
  end

  def test_expiring_orders
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
    assert_select("td", "$39.00")
    get "/orders"
    assert_select("td", "Draft")
    post "/orders/expire"
    follow_redirect!
    assert_select("td", "Expired")
  end

  def test_cancel
    shopify_id = register_customer("Shopify")

    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
    assert_select("td", "$39.00")
    post "/orders",
         params: {
           "authenticity_token" => "[FILTERED]",
           "order_id" => order_id,
           "customer_id" => shopify_id,
           "commit" => "Submit order"
         }

    post "/orders/#{order_id}/cancel"
    follow_redirect!
    get "/orders/#{order_id}"
    assert_select("dd", "Cancelled")
  end

  def test_have_happy_hour_applied
    shopify_id = SecureRandom.uuid
    run_command(
      Crm::RegisterCustomer.new(customer_id: shopify_id, name: "Shopify")
    )

    order_id = SecureRandom.uuid

    async_remote_id = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: async_remote_id,
        name: "Async Remote"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: async_remote_id, price: 39))

    run_command(
      Pricing::CreateHappyHour.new(
        details: {
          name: "Night Owls",
          code: "owls",
          discount: "25",
          start_hour: "20",
          end_hour: "2",
          product_ids: [async_remote_id]
        }
      )
    )

    timestamp = DateTime.new(2021, 11, 24, 01, 04, 44).utc

    travel_to(timestamp) do
      get "/"
      get "/orders/new"
      post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
      follow_redirect!
      assert_select("td", "Before discounts")
      assert_select("td#before-discounts-value", "$39.00")
      assert_select("td", "After happy hour discounts")
      assert_select("td#happy-hour-value", "$29.25")

      post "/orders",
          params: {
            "authenticity_token" => "[FILTERED]",
            "order_id" => order_id,
            "customer_id" => shopify_id,
            "commit" => "Submit order"
          }
      follow_redirect!
      assert_select("td", "Before discounts")
      assert_select("td", "$39.00")
      assert_select("td", "After happy hour discounts")
      assert_select("td", "$29.25")
    end
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
    assert_select("a", "Edit discount")
    get "/orders/#{order_id}/edit_discount"
    assert_select("label", "Percentage")

    post "/orders/#{order_id}/update_discount?amount=10"
    follow_redirect!
    assert_select("td", "$123.30")
  end
end
