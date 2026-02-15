require "test_helper"

class CustomersTest < InMemoryRESIntegrationTestCase
  def setup
    super
    register_store("Store 1")
    add_available_vat_rate(10)
  end

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

    order_and_pay(customer_id, product_1_id, product_2_id)
    visit_customers_index

    assert_customer_summary("Customer Shop", "$7.00")
    assert_customer_summary("BigCorp Ltd", "$0.00")

    order_and_pay(customer_id, product_1_id)
    visit_customers_index

    assert_customer_summary("Customer Shop", "$11.00")
    assert_customer_summary("BigCorp Ltd", "$0.00")
  end

  def test_customer_details
    customer_id = register_customer("Customer Shop")
    product_id = register_product("Fearless Refactoring", 4, 10)

    order_uid = order_and_pay(customer_id, product_id)

    get "/orders/#{order_uid}"
    header_text = css_select("header h1").first.text
    order_number = header_text.gsub("Order ", "").strip

    visit_customer_page(customer_id)

    assert_select "h1", "Customer Page"
    assert_customer_details "Customer Shop", "No"
    assert_customer_orders_table order_number, "Paid", "$4.00", "$4.00"
  end

  def test_customer_can_be_registered_in_store
    register_customer("Customer Shop")

    get("/customers")
    assert_response(:success)
    assert_select("td", "Customer Shop")
  end

  def test_index_only_shows_customers_from_current_store
    store_1_id = register_store("Store 1")
    store_2_id = register_store("Store 2")

    post(switch_store_path, params: { store_id: store_1_id })
    customer_1_id = register_customer("Customer in Store 1")

    post(switch_store_path, params: { store_id: store_2_id })
    customer_2_id = register_customer("Customer in Store 2")

    get("/customers")
    assert_response(:success)
    assert_select("td", "Customer in Store 2")
    assert_select("td", {count: 0, text: "Customer in Store 1"})

    post(switch_store_path, params: { store_id: store_1_id })
    get("/customers")
    assert_response(:success)
    assert_select("td", "Customer in Store 1")
    assert_select("td", {count: 0, text: "Customer in Store 2"})
  end

  def test_show_prevents_access_to_customer_from_another_store
    store_1_id = register_store("Store 1")
    store_2_id = register_store("Store 2")

    post(switch_store_path, params: { store_id: store_1_id })
    customer_1_id = register_customer("Customer in Store 1")

    post(switch_store_path, params: { store_id: store_2_id })

    get("/customers/#{customer_1_id}")
    assert_response(:not_found)
  end

  def test_update_prevents_access_to_customer_from_another_store
    store_1_id = register_store("Store 1")
    store_2_id = register_store("Store 2")

    post(switch_store_path, params: { store_id: store_1_id })
    customer_1_id = register_customer("Customer in Store 1")

    post(switch_store_path, params: { store_id: store_2_id })

    patch("/customers/#{customer_1_id}")
    assert_response(:not_found)
  end

  private

  def order_and_pay(customer_id, *product_ids)
    order_id = create_order
    product_ids.each do |product_id|
      add_product_to_basket(order_id, product_id)
    end
    submit_order(customer_id, order_id)
    pay_order(order_id)
    order_id
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
