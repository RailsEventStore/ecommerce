require_relative "../test_helper"

class ClientOrdersTests < InMemoryRESIntegrationTestCase
  include ActionView::Helpers::NumberHelper
  cover "ClientOrders*"

  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    ClientOrders::Client.destroy_all
    ClientOrders::Order.destroy_all
    Orders::Order.destroy_all
  end

  def test_happy_path
    arkency_id = register_customer('Arkency')
    async_remote_id = register_product("Async Remote", 39, 10)
    Sidekiq::Job.drain_all

    get "/clients"
    assert_select("button", { count: 0, text: "Log out" })
    assert_select("button", "Login")
    assert_select("select", "Arkency")

    login(arkency_id)
    assert_select("h1", "Arkency")
    assert_select("p", "No orders to display.")

    order_id = SecureRandom.uuid
    add_item_to_basket_for_order(async_remote_id, order_id)
    Sidekiq::Job.drain_all
    submit_order_for_customer(arkency_id, order_id)
    Sidekiq::Job.drain_all
    get "/client_orders"
    order_price = number_to_currency(Orders::Order.find_by(uid: order_id).discounted_value)

    assert_select("td", "Submitted")
    assert_select("td", order_price)

    pay_order(order_id)
    Sidekiq::Job.drain_all
    get "/client_orders"
    assert_select("td", "Paid")

    cancel_submitted_order_for_customer(arkency_id)
    Sidekiq::Job.drain_all
    get "/client_orders"
    assert_select("td", "Cancelled")

    assert_select("button", "Log out")
    get "/logout"
    follow_redirect!
    assert_select("button", "Login")
    assert_select("select", "Arkency")
  end

  def test_creating_order_as_client
    arkency_id = register_customer('Arkency')
    async_remote_id = register_product("Async Remote", 39, 10)
    Sidekiq::Job.drain_all

    get "/clients"
    login(arkency_id)
    order_id = SecureRandom.uuid
    get "/client_orders/new"
    as_client_add_item_to_basket_for_order(async_remote_id, order_id)
    Sidekiq::Job.drain_all
    as_client_submit_order_for_customer(order_id)
    Sidekiq::Job.drain_all
    get "/client_orders"
    order_price = number_to_currency(Orders::Order.find_by(uid: order_id).discounted_value)
    assert_select("td", "Submitted")
    assert_select("td", order_price)
  end

  def test_paid_orders_summary
    customer_id = register_customer("Customer Shop")
    product_1_id = register_product("Fearless Refactoring", 4, 10)
    product_2_id = register_product("Asycn Remote", 3, 10)
    Sidekiq::Job.drain_all

    login(customer_id)
    visit_client_orders
    assert_select "Total orders summary", false

    order_and_pay(customer_id, SecureRandom.uuid, product_1_id, product_2_id)
    visit_client_orders

    assert_orders_summary("$7.00")

    order_and_pay(customer_id, SecureRandom.uuid, product_1_id)
    visit_client_orders

    assert_orders_summary("$11.00")
  end

  private

  def submit_order_for_customer(customer_id, order_id)
    post "/orders", params: { order_id: order_id, customer_id: customer_id }
    Sidekiq::Job.drain_all
    follow_redirect!
  end

  def add_item_to_basket_for_order(async_remote_id, order_id)
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
  end

  def as_client_submit_order_for_customer(order_id)
    post "/client_orders", params: { order_id: order_id }
    follow_redirect!
  end

  def as_client_add_item_to_basket_for_order(async_remote_id, order_id)
    post "/client_orders/#{order_id}/add_item?product_id=#{async_remote_id}"
  end

  def cancel_order(order_id)
    post "/orders/#{order_id}/cancel"
  end

  def cancel_submitted_order_for_customer(customer_id)
    order_id = SecureRandom.uuid
    anti_if = register_product('Anti If', 99, 10)
    Sidekiq::Job.drain_all

    add_item_to_basket_for_order(anti_if, order_id)
    add_item_to_basket_for_order(anti_if, order_id)
    submit_order_for_customer(customer_id, order_id)
    cancel_order(order_id)
  end

  def order_and_pay(customer_id, order_id, *product_ids)
    product_ids.each do |product_id|
      as_client_add_item_to_basket_for_order(product_id, order_id)
    end
    submit_order_for_customer(customer_id, order_id)
    pay_order(order_id)
    Sidekiq::Job.drain_all
  end

  def assert_orders_summary(summary)
    assert_select 'tr' do
      assert_select 'td:nth-child(1)', "Total orders summary"
      assert_select 'td:nth-child(2)', summary
    end
  end

  def update_price(product_id, new_price)
    patch "/products/#{product_id}",
         params: {
           "authenticity_token" => "[FILTERED]",
           "product_id" => product_id,
           price: new_price,
         }
  end
end
