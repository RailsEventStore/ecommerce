require "test_helper"

class ThreePlusOneFreeTest < InMemoryRESIntegrationTestCase
  def setup
    super
    Rails.configuration.payment_gateway.call.reset
    Rails.configuration.event_store.subscribe(
      Processes::ThreePlusOneFree.new(
        Rails.configuration.event_store,
        Rails.configuration.command_bus
      ),
      to: Processes::ThreePlusOneFree.subscribed_events
    )
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

    submit_order(customer_id, order_id)
    post "/orders/#{order_id}/pay"
    assert_payment_gateway_value(162.0)
    assert_invoice_values(order_id)
  end

  private

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

    assert_select("td", "Product")
    assert_select("td", "$13.50")
    assert_select("td", "$54.00")
    assert_select("td", "Premium")
    assert_select("td", "$27.00")
    assert_select("td", "$108.00")
    assert_select("td", "$162.00")
  end

  def apply_discount_10_percent(order_id)
    post "/orders/#{order_id}/update_discount?amount=10"
  end
end
