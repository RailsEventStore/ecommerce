require "test_helper"

class DiscountTest < InMemoryRESIntegrationTestCase
  def setup
    super
    add_available_vat_rate(10)
  end

  def test_remove_discount
    register_customer("Shopify")

    async_remote_id = register_product("Async Remote", 137, 10)

    get "/"
    get "/orders/new"
    follow_redirect!
    order_id = retrieve_order_id_from_url

    post "/orders/#{order_id}/add_item?product_id=#{async_remote_id}"
    get "/orders/#{order_id}/edit"
    assert_select("td", "$137.00")
    assert_select("a", count: 0, text: "Remove")

    apply_discount_10_percent(order_id)

    assert_select("button", "Remove")
    post "/orders/#{order_id}/remove_discount"
    follow_redirect!
    assert_select("td", "$137.00")
    assert_select("a", count: 0, text: "Remove")
  end

  private

  def retrieve_order_id_from_url
    request.path.split('/')[2]
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
