require "test_helper"

class StoreSwitchingTest < InMemoryRESIntegrationTestCase
  def test_first_store_selected_by_default_when_no_cookie
    store_a_id = register_store("Store A")
    register_store("Store B")

    get products_path

    assert_response :success
    assert_equal(store_a_id, cookies[:current_store_id])
  end

  def test_cookie_is_preserved_across_requests
    store_1_id = register_store("Store A")
    store_2_id = register_store("Store B")

    get products_path
    assert_equal(store_1_id, cookies[:current_store_id])

    post switch_store_path, params: { store_id: store_2_id }
    assert_equal(store_2_id, cookies[:current_store_id])

    get products_path
    assert_equal(store_2_id, cookies[:current_store_id])
  end

  def test_fallback_to_first_store_when_cookie_points_to_nonexistent_store
    store_a_id = register_store("Store A")
    register_store("Store B")
    nonexistent_store_id = SecureRandom.uuid

    cookies[:current_store_id] = nonexistent_store_id

    get products_path

    assert_response :success
    assert_equal(store_a_id, cookies[:current_store_id])
  end

  def test_switching_stores_updates_cookie
    store_a_id = register_store("Store A")
    store_2_id = register_store("Store B")

    get products_path
    assert_equal(store_a_id, cookies[:current_store_id])

    post switch_store_path, params: { store_id: store_2_id }
    follow_redirect!

    assert_equal(store_2_id, cookies[:current_store_id])
    assert_response :success
  end

  def test_dropdown_shows_all_stores
    store_1_id = register_store("Store A")
    store_2_id = register_store("Store B")
    store_3_id = register_store("Store C")

    get products_path

    assert_select "select[name='store_id']" do
      assert_select "option[value='#{store_1_id}']", "Store A"
      assert_select "option[value='#{store_2_id}']", "Store B"
      assert_select "option[value='#{store_3_id}']", "Store C"
    end
  end

  def test_dropdown_shows_current_store_as_selected
    store_1_id = register_store("Store A")
    store_2_id = register_store("Store B")

    post switch_store_path, params: { store_id: store_2_id }
    follow_redirect!

    get products_path

    assert_select "select[name='store_id']" do
      assert_select "option[value='#{store_1_id}'][selected]", false
      assert_select "option[value='#{store_2_id}'][selected='selected']", "Store B"
    end
  end
end
