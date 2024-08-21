require "test_helper"

class DiscountTest < InMemoryRESIntegrationTestCase
  def setup
    super
    Orders::Order.destroy_all
    add_available_vat_rate(10)
  end

  def test_reset_discount
    register_customer("Shopify")
    order_id = SecureRandom.uuid

    async_remote_id = register_product("Async Remote", 137, 10)

    get "/"
    get "/orders/new"
    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    get "/orders/#{order_id}/edit"
    assert_select("td", "$137.00")
    assert_select("a", count: 0, text: "Reset")

    apply_discount_10_percent(order_id)

    assert_select("button", "Reset")
    post "/orders/#{order_id}/reset_discount"
    follow_redirect!
    assert_select("td", "$137.00")
    assert_select("a", count: 0, text: "Reset")
  end

  private

  def apply_discount_10_percent(order_id)
    assert_select("a", "Edit discount")
    get "/orders/#{order_id}/edit_discount"
    assert_select("label", "Percentage")

    post "/orders/#{order_id}/update_discount?amount=10"
    follow_redirect!
    assert_select("td", "$123.30")
  end
end
