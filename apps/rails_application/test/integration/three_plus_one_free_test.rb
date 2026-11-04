require "test_helper"

class ThreePlusOneFreeTest < InMemoryRESIntegrationTestCase
  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    register_store("Store 1")
    add_available_vat_rate(10)
  end

  def test_recalculates_one_free_unit_and_uses_the_same_totals_for_payment_and_invoice
    customer_id = register_customer("Shopify")
    cheaper_product_id = register_product("Cheaper", 10, 10)
    product_id = register_product("Product", 20, 10)
    premium_product_id = register_product("Premium", 30, 10)
    supply_product(cheaper_product_id, 1)
    supply_product(product_id, 4)
    supply_product(premium_product_id, 4)
    order_id = create_order

    4.times { add_product_to_basket(order_id, product_id) }
    assert_order_total(order_id, "$60.00")

    add_product_to_basket(order_id, cheaper_product_id)
    assert_order_total(order_id, "$80.00")

    post "/orders/#{order_id}/remove_item?product_id=#{cheaper_product_id}"
    assert_order_total(order_id, "$60.00")

    4.times { add_product_to_basket(order_id, premium_product_id) }
    apply_discount_10_percent(order_id)
    assert_order_total(order_id, "$162.00")
    assert_discount_breakdown("/orders/#{order_id}/edit")

    submit_order(customer_id, order_id)
    assert_discount_breakdown("/orders/#{order_id}")
    login(customer_id)
    assert_discount_breakdown("/client_orders/#{order_id}")
    assert_order_show_promotion(order_id, "$20.00")
    post "/orders/#{order_id}/pay"
    assert_payment_gateway_value(162.0)
    assert_invoice_values(order_id)
  end

  def test_displays_the_reward_as_it_qualifies_changes_and_is_removed
    cheaper_product_id = register_product("Cheaper", 10, 10)
    product_id = register_product("Product", 20, 10)
    supply_product(cheaper_product_id, 1)
    supply_product(product_id, 4)
    order_id = create_order

    3.times { add_product_to_basket(order_id, product_id) }
    assert_no_promotion(order_id)

    add_product_to_basket(order_id, product_id)
    assert_promotion(order_id, "$20.00")

    add_product_to_basket(order_id, cheaper_product_id)
    assert_promotion(order_id, "$10.00")

    post "/orders/#{order_id}/remove_item?product_id=#{cheaper_product_id}"
    assert_promotion(order_id, "$20.00")

    post "/orders/#{order_id}/remove_item?product_id=#{product_id}"
    assert_no_promotion(order_id)
  end

  def test_line_total_matches_invoice_when_discounted_units_require_rounding
    customer_id = register_customer("Shopify")
    product_id = register_product("Product", 19.99, 10)
    supply_product(product_id, 4)
    order_id = create_order
    4.times { add_product_to_basket(order_id, product_id) }
    apply_discount_10_percent(order_id)

    get "/orders/#{order_id}/edit"
    assert_select("tbody tr", text: /Product/) do
      assert_select("td", "$79.96")
      assert_select("td", "$53.97")
    end
    assert_select("tfoot tr", text: /You save/) { assert_select("td", "$25.99") }

    submit_order(customer_id, order_id)
    get "/orders/#{order_id}"
    assert_select("tbody tr", text: /Product/) { assert_select("td", "$53.97") }
    issue_invoice(order_id)
    assert_select("td", "$13.49")
    assert_select("td", "$13.50")
    assert_select("tfoot td", "$53.97")
  end

  private

  def assert_discount_breakdown(path)
    get path
    assert_select("th", "Unit price before discounts")
    assert_select("th", "Line total after discounts")
    assert_select("tbody tr", text: /Product/) do
      assert_select("td", "$20.00")
      assert_select("td", "$80.00")
      assert_select("td", "$54.00")
    end
    assert_select("tbody tr", text: /Premium/) do
      assert_select("td", "$120.00")
      assert_select("td", "$108.00")
    end
    assert_select("tfoot tr", text: /Before discounts/) { assert_select("td", "$200.00") }
    assert_select("tfoot tr", text: /You save/) { assert_select("td", "$38.00") }
    assert_select("tfoot tr", text: /Total/) { assert_select("td", "$162.00") }
  end

  def assert_promotion(order_id, saving)
    get "/orders/#{order_id}/edit"
    assert_select("tr#orders_order_#{order_id}_free_product_saving_row") do
      assert_select("td", "3+1 — cheapest item free")
      assert_select("td", "-#{saving}")
    end
  end

  def assert_no_promotion(order_id)
    get "/orders/#{order_id}/edit"
    assert_select("tr#orders_order_#{order_id}_free_product_saving_row:empty")
  end

  def assert_order_show_promotion(order_id, saving)
    get "/orders/#{order_id}"
    assert_select("tfoot tr", text: /3\+1 — cheapest item free/) do
      assert_select("td", "-#{saving}")
    end
  end

  def assert_order_total(order_id, total)
    get "/orders/#{order_id}/edit"
    assert_select("td", total)
  end

  def assert_payment_gateway_value(value)
    assert_equal(
      value,
      Rails.configuration.payment_gateway.call.authorized_transactions.fetch(0).fetch(1)
    )
  end

  def assert_invoice_values(order_id)
    issue_invoice(order_id)

    assert_select("td", "Product")
    assert_select("td", "$13.50")
    assert_select("td", "$54.00")
    assert_select("td", "Premium")
    assert_select("td", "$27.00")
    assert_select("td", "$108.00")
    assert_select("td", "$162.00")
  end

  def issue_invoice(order_id)
    get "/orders/#{order_id}"
    get "/orders/#{order_id}/billing_address/edit"
    put "/orders/#{order_id}/billing_address",
        params: {
          "invoices_invoice" => {
            address_line_1: "44 Main Street",
            address_line_2: "Apt 2",
            address_line_3: "Francisco",
            address_line_4: "UK"
          }
        }
    post "/orders/#{order_id}/invoice"
    follow_redirect!
  end

  def apply_discount_10_percent(order_id)
    post "/orders/#{order_id}/update_discount?amount=10"
  end
end
