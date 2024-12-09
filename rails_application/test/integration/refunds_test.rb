require "test_helper"

class RefundsTest < InMemoryRESIntegrationTestCase
  def setup
    super
    add_available_vat_rate(10)
  end

  def test_happy_path
    shopify_id = register_customer("Shopify")
    order_id = SecureRandom.uuid
    async_remote_id = register_product("Async Remote", 39, 10)
    fearless_id = register_product("Fearless Refactoring", 49, 10)

    add_product_to_basket(order_id, async_remote_id)
    add_product_to_basket(order_id, fearless_id)
    add_product_to_basket(order_id, fearless_id)
    submit_order(shopify_id, order_id)

    get "/orders/#{order_id}"

    assert_select("a", "Refund")

    get "/orders/#{order_id}/refunds/new"

    assert_order_line_row(async_remote_id, "Async Remote", 1)
    assert_order_line_row(fearless_id, "Fearless Refactoring", 2)
  end

  private

  def assert_order_line_row(product_id, product_name, quantity)
    assert_select("#order_line_product_#{product_id}") do
      assert_select("td", product_name)
      assert_select("td", "0 / #{quantity}")
    end
  end
end
