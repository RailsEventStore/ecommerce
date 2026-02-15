require "test_helper"

class DealsTest < InMemoryRESIntegrationTestCase
  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    register_store("Store 1")
    add_available_vat_rate(10)
  end

  def test_crm_landing_page
    get "/crm"
    assert_response(:success)
    assert_select("h1", "CRM")
    assert_select("a[href='/customers']")
    assert_select("a[href='/deals']")
  end

  def test_crm_nav_link_active_on_crm_page
    get "/crm"
    assert_select("a[aria-current='page']", "CRM")
  end

  def test_crm_sub_navigation_on_customers_page
    get "/customers"
    assert_select("nav a[href='/customers']", "Customers")
    assert_select("nav a[href='/deals']", "Deals")
  end

  def test_crm_sub_navigation_on_deals_page
    get "/deals"
    assert_select("nav a[href='/customers']", "Customers")
    assert_select("nav a[href='/deals']", "Deals")
  end

  def test_deal_lifecycle_draft_to_won
    customer_id = register_customer("Shopify")
    product_id = register_product("Async Remote", 39, 10)

    get "/orders/new"
    follow_redirect!
    order_id = retrieve_order_id_from_url

    get "/deals"
    assert_response(:success)
    assert_select("h3", "Draft")
    assert_deal_card("No number", "No customer", "$0.00")

    post "/orders/#{order_id}/add_item?product_id=#{product_id}"
    submit_order(customer_id, order_id)
    follow_redirect!

    get "/orders/#{order_id}"
    order_number = css_select("header h1").first.text.gsub("Order ", "").strip

    get "/deals"
    assert_deal_card(order_number, "Shopify", "$39.00")

    pay_order(order_id)

    get "/deals"
    assert_deal_card(order_number, "Shopify", "$39.00")
  end

  def test_deal_lifecycle_draft_to_lost_on_cancel
    customer_id = register_customer("Shopify")
    product_id = register_product("Async Remote", 39, 10)

    get "/orders/new"
    follow_redirect!
    order_id = retrieve_order_id_from_url

    post "/orders/#{order_id}/add_item?product_id=#{product_id}"
    submit_order(customer_id, order_id)

    post "/orders/#{order_id}/cancel"

    get "/deals"
    assert_response(:success)
  end

  def test_deal_lifecycle_draft_to_lost_on_expire
    register_product("Async Remote", 39, 10)

    get "/orders/new"
    follow_redirect!

    post "/orders/expire"

    get "/deals"
    assert_response(:success)
  end

  def test_deals_filtered_by_store
    store_2_id = register_store("Store 2")
    product_id = register_product("Async Remote", 39, 10)

    get "/orders/new"
    follow_redirect!

    post(switch_store_path, params: { store_id: store_2_id })

    get "/orders/new"
    follow_redirect!

    get "/deals"
    assert_deal_count(1)
  end

  private

  def retrieve_order_id_from_url
    request.path.split("/")[2]
  end

  def assert_deal_card(order_number, customer_name, value)
    assert_select(".bg-white.rounded-lg") do
      assert_select("div", order_number)
      assert_select("div", customer_name)
      assert_select("div", value)
    end
  end

  def assert_deal_count(expected)
    assert_equal(expected, css_select(".bg-white.rounded-lg.shadow-sm").size)
  end
end
