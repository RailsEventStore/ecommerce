require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  cover "OrdersController#show"

  def setup
    @store_id_a = SecureRandom.uuid
    @store_id_b = SecureRandom.uuid
    post "/admin/stores", params: { store_id: @store_id_a, name: "Store A" }
    post "/admin/stores", params: { store_id: @store_id_b, name: "Store B" }
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

  private

  def event_store
    Rails.configuration.event_store
  end
end
