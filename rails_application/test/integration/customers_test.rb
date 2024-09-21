require "test_helper"

class CustomersTest < InMemoryRESIntegrationTestCase
  def test_list_customers
    get "/customers"
    assert_response :success
  end

  def test_vips
    customer_id = register_customer("Customer Shop")

    patch "/customers/#{customer_id}"
    follow_redirect!
    assert_select("td", "Already a VIP")
  end

  def test_paid_orders_summary
    register_customer("BigCorp Ltd")
    customer_id = register_customer("Customer Shop")
    product_1_id = register_product("Fearless Refactoring", 4, 10)
    product_2_id = register_product("Asycn Remote", 3, 10)

    visit_customers_index
    assert_customer_summary("Customer Shop", "$0.00")
    assert_customer_summary("BigCorp Ltd", "$0.00")

    order = new_order

    order_and_pay(customer_id, new_order.id, product_1_id, product_2_id)
    visit_customers_index

    assert_customer_summary("Customer Shop", "$7.00")
    assert_customer_summary("BigCorp Ltd", "$0.00")

    another_order = new_order

    order_and_pay(customer_id, another_order.id, product_1_id)
    visit_customers_index

    assert_customer_summary("Customer Shop", "$11.00")
    assert_customer_summary("BigCorp Ltd", "$0.00")
  end

  def test_customer_details
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)

    order_id = new_order.id

    order_and_pay(customer_id, order_id, product_id)
    visit_customer_page(customer_id)

    order = Order.find(order_id)

    assert_select("h1", "Customer Page")
    assert_customer_details("Customer Shop", "No")
    assert_customer_orders_table(order.number, "Paid", "$4.00", "$4.00")
  end

  private

  def order_and_pay(customer_id, order_id, *product_ids)
    product_ids.each do |product_id|
      add_product_to_basket(order_id, product_id)
    end
    submit_order(customer_id, order_id)
    pay_order(order_id)
  end

  def assert_customer_summary(customer_name, summary)
    assert_select "tr" do
      assert_select "td:nth-child(1)", customer_name
      assert_select "td:nth-child(3)", summary
    end
  end

  def assert_customer_details(customer_name, vip_status)
    assert_select "dt", "Name"
    assert_select "dd", customer_name
    assert_select "dt", "VIP"
    assert_select "dd", vip_status
  end

  def assert_customer_orders_table(
    order_number,
    order_state,
    order_discounted_value,
    paid_orders_summary
  )
    assert_select "table" do
      assert_select "tbody" do
        assert_select "tr" do
          assert_select "td", order_number
          assert_select "td", order_state
          assert_select "td", order_discounted_value
        end
        assert_select "tr" do
          assert_select "td:nth-child(2)", paid_orders_summary
        end
      end
    end
  end
end
