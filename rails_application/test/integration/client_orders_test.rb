require "test_helper"

class ClientOrdersTests < InMemoryRESIntegrationTestCase
  cover "ClientOrders*"

  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    ClientOrders::Client.destroy_all
    ClientOrders::Order.destroy_all
  end

  def test_happy_path
    shopify_id = SecureRandom.uuid
    arkency_id = SecureRandom.uuid
    run_command(
      Crm::RegisterCustomer.new(customer_id: shopify_id, name: "Shopify")
    )
    run_command(
      Crm::RegisterCustomer.new(customer_id: arkency_id, name: "Arkency")
    )

    async_remote_id = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: async_remote_id,
        name: "Async Remote"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: async_remote_id, price: 39))

    get "/client"

    assert_select("button", "Login")
    assert_select("select", "Shopify\nArkency")

    login(arkency_id)

    assert_select("p", "No orders to display.")

    order_id = SecureRandom.uuid
    run_command(Ordering::AddItemToBasket.new(product_id: async_remote_id, order_id: order_id))
    run_command(Ordering::AddItemToBasket.new(product_id: async_remote_id, order_id: order_id))
    run_command(Ordering::SubmitOrder.new(order_id: order_id, customer_id: arkency_id))

    login(arkency_id)

    assert_select("td", "Submitted")

    pay(order_id)

    login(arkency_id)

    assert_select("td", "Paid")

    cancel_submitted_order(arkency_id)

    login(arkency_id)

    assert_select("td", "Cancelled")
  end

  private

  def cancel_submitted_order(arkency_id)
    order_id = SecureRandom.uuid
    anti_if = SecureRandom.uuid
    run_command(
      ProductCatalog::RegisterProduct.new(
        product_id: anti_if,
        name: "Anti If"
      )
    )
    run_command(Pricing::SetPrice.new(product_id: anti_if, price: 99))
    run_command(Ordering::AddItemToBasket.new(product_id: anti_if, order_id: order_id))
    run_command(Ordering::AddItemToBasket.new(product_id: anti_if, order_id: order_id))
    run_command(Ordering::SubmitOrder.new(order_id: order_id, customer_id: arkency_id))
    run_command(Ordering::CancelOrder.new(order_id: order_id))
  end

  def pay(order_id)
    run_command(Payments::AuthorizePayment.new(order_id: order_id))
    run_command(Payments::CapturePayment.new(order_id: order_id))
  end

  def login(arkency_id)
    post "/client", params: { client_id: arkency_id }
    follow_redirect!
  end
end
