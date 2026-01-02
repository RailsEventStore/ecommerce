require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  cover "OrdersController#show"
  cover "OrdersController#add_item"
  cover "OrdersController#remove_item"
  cover "OrdersController#create"

  def setup
    @store_id_a = SecureRandom.uuid
    @store_id_b = SecureRandom.uuid
    post "/admin/stores", params: { store_id: @store_id_a, name: "Store A" }
    post "/admin/stores", params: { store_id: @store_id_b, name: "Store B" }
    post "/available_vat_rates", params: { code: "10", rate: 10 }
  end

  def test_show_returns_not_found_when_order_does_not_exist
    post "/switch_store", params: { store_id: @store_id_a }
    get "/orders/#{SecureRandom.uuid}"

    assert_response(:not_found)
  end

  def test_show_returns_not_found_when_order_belongs_to_different_store
    post "/switch_store", params: { store_id: @store_id_b }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]

    post "/switch_store", params: { store_id: @store_id_a }
    get "/orders/#{order_id}"

    assert_response(:not_found)
  end

  def test_show_allows_access_to_order_without_store_id
    order_id = SecureRandom.uuid
    event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))

    post "/switch_store", params: { store_id: @store_id_a }
    get "/orders/#{order_id}"

    assert_response(:success)
  end

  def test_show_allows_access_to_order_in_current_store
    post "/switch_store", params: { store_id: @store_id_a }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]

    get "/orders/#{order_id}"

    assert_response(:success)
  end

  def test_add_item_returns_not_found_when_order_belongs_to_different_store
    product_id = register_product("Test Product", 100, 10)

    post "/switch_store", params: { store_id: @store_id_b }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]

    post "/switch_store", params: { store_id: @store_id_a }
    post "/orders/#{order_id}/add_item?product_id=#{product_id}"

    assert_response(:not_found)
  end

  def test_add_item_allows_access_to_order_in_current_store
    product_id = register_product("Test Product", 100, 10)

    post "/switch_store", params: { store_id: @store_id_a }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]

    post "/orders/#{order_id}/add_item?product_id=#{product_id}"

    assert_response(:success)
  end

  def test_add_item_allows_access_to_order_without_store_id
    product_id = register_product("Test Product", 100, 10)
    order_id = SecureRandom.uuid
    event_store.publish(Pricing::OfferDrafted.new(data: { order_id: order_id }))

    post "/switch_store", params: { store_id: @store_id_a }
    post "/orders/#{order_id}/add_item?product_id=#{product_id}"

    assert_response(:success)
  end

  def test_remove_item_returns_not_found_when_order_belongs_to_different_store
    product_id = register_product("Test Product", 100, 10)

    post "/switch_store", params: { store_id: @store_id_b }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]

    post "/switch_store", params: { store_id: @store_id_a }
    post "/orders/#{order_id}/remove_item?product_id=#{product_id}"

    assert_response(:not_found)
  end

  def test_remove_item_allows_access_to_order_in_current_store
    product_id = register_product("Test Product", 100, 10)

    post "/switch_store", params: { store_id: @store_id_a }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]
    post "/orders/#{order_id}/add_item?product_id=#{product_id}"

    post "/orders/#{order_id}/remove_item?product_id=#{product_id}"

    assert_response(:success)
  end

  def test_create_returns_not_found_when_order_belongs_to_different_store
    customer_id = register_customer("Test Customer")

    post "/switch_store", params: { store_id: @store_id_b }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]

    post "/switch_store", params: { store_id: @store_id_a }
    post "/orders", params: { order_id: order_id, customer_id: customer_id }

    assert_response(:not_found)
  end

  def test_create_allows_access_to_order_in_current_store
    customer_id = register_customer("Test Customer")
    product_id = register_product("Test Product", 100, 10)

    post "/switch_store", params: { store_id: @store_id_a }
    get "/orders/new"
    follow_redirect!
    order_id = request.path.split('/')[2]
    post "/orders/#{order_id}/add_item?product_id=#{product_id}"

    post "/orders", params: { order_id: order_id, customer_id: customer_id }

    assert_redirected_to order_path(order_id)
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def register_product(name, price, vat_rate_code)
    product_id = SecureRandom.uuid
    post "/products", params: { product_id: product_id, name: name, price: price, vat_rate_code: vat_rate_code }
    product_id
  end

  def register_customer(name)
    customer_id = SecureRandom.uuid
    post "/customers", params: { customer_id: customer_id, name: name }
    customer_id
  end
end
