require "test_helper"

class AdminStoresTest < InMemoryRESIntegrationTestCase
  def test_register_and_rename_store
    get "/admin/stores"
    assert_response :success
    assert_select("a", "New Store")

    get "/admin/stores/new"
    assert_response :success

    store_id = css_select("input[name='store_id']").first["value"]

    post "/admin/stores", params: {
      store_id: store_id,
      name: "Store 1"
    }
    follow_redirect!
    assert_response :success

    store = Admin::Store.find(store_id)
    assert_equal("Store 1", store.name)

    assert_select("p", "Store was successfully created")

    get "/admin/stores"
    assert_select("td", "Store 1")
    assert_select("a", "New Store")

    get "/admin/stores/#{store_id}/edit"
    assert_response :success

    patch "/admin/stores/#{store_id}", params: {
      name: "Store 2"
    }
    follow_redirect!
    assert_response :success

    store.reload
    assert_equal("Store 2", store.name)

    assert_select("p", "Store was successfully updated")

    get "/admin/stores"
    assert_select("td", "Store 2")
  end

  def test_empty_name_is_rejected
    get "/admin/stores/new"
    assert_response :success

    store_id = css_select("input[name='store_id']").first["value"]

    post "/admin/stores", params: {
      store_id: store_id,
      name: ""
    }

    assert_response :success
    assert_select("span", "Store name cannot be empty")
    refute Admin::Store.exists?(store_id)
  end
end
