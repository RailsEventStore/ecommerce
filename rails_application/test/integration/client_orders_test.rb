require "test_helper"

class ClientOrdersTests < InMemoryRESIntegrationTestCase
  cover "ClientOrders*"

  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    ClientOrders::Client.destroy_all
    ClientOrders::Order.destroy_all
    Orders::Order.destroy_all
  end

  def test_happy_path
    register_customer('Shopify')
    arkency_id = register_customer('Arkency')
    async_remote_id = register_product("Async Remote", 39, 10)

    get "/client"

    assert_select("button", "Login")
    assert_select("select", "Shopify\nArkency")

    login(arkency_id)
    assert_select("p", "No orders to display.")

    order_id = SecureRandom.uuid
    add_item_to_basket_for_order(async_remote_id, order_id)
    submit_order_for_customer(arkency_id, order_id)

    login(arkency_id)
    assert_select("td", "Submitted")

    pay_order(order_id)

    login(arkency_id)

    assert_select("td", "Paid")

    cancel_submitted_order_for_customer(arkency_id)

    login(arkency_id)

    assert_select("td", "Cancelled")
  end

  private

  def register_product(name, price, vat_rate)
    async_remote_id = SecureRandom.uuid
    post "/products", params: { product_id: async_remote_id, name: name, price: price, vat_rate: vat_rate }
    async_remote_id
  end

  def register_customer(name)
    customer_id = SecureRandom.uuid
    post "/customers", params: { customer_id: customer_id, name: name }
    customer_id
  end

  def submit_order_for_customer(customer_id, order_id)
    post "/orders", params: { order_id: order_id, customer_id: customer_id }
    follow_redirect!
  end

  def add_item_to_basket_for_order(async_remote_id, order_id)
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    follow_redirect!
  end

  def pay_order(order_id)
    post "/orders/#{order_id}/pay"
  end

  def cancel_submitted_order_for_customer(customer_id)
    order_id = SecureRandom.uuid
    anti_if = register_product('Anti If', 99, 10)

    add_item_to_basket_for_order(anti_if, order_id)
    add_item_to_basket_for_order(anti_if, order_id)
    submit_order_for_customer(customer_id, order_id)

    run_command(Ordering::CancelOrder.new(order_id: order_id))
  end

  def login(arkency_id)
    post "/client", params: { client_id: arkency_id }
    follow_redirect!
  end
end