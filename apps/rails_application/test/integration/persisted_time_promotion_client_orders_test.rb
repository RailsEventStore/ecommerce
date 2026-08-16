require "test_helper"

class PersistedTimePromotionClientOrdersTest < RealRESIntegrationTestCase
  def setup
    @customer_id = SecureRandom.uuid

    post "/admin/stores", params: { store_id: SecureRandom.uuid, name: "Test Store" }
    post "/customers", params: { customer_id: @customer_id, name: "BigCorp" }
  end

  def test_creates_client_order_with_persisted_active_time_promotion
    post "/time_promotions", params: {
      label: "Active promotion",
      discount: "50",
      start_time: 1.hour.ago.strftime("%Y-%m-%dT%H:%M"),
      end_time: 1.hour.from_now.strftime("%Y-%m-%dT%H:%M")
    }

    post "/login", params: { client_id: @customer_id }
    get "/client_orders/new"

    assert_response(:redirect)
    assert_match(%r{/client_orders/.+/edit}, response.location)
  end
end
