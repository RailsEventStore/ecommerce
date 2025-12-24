require "test_helper"

class VatRatesSecurityTest < InMemoryRESIntegrationTestCase
  def test_user_can_only_see_vat_rates_from_their_current_store
    store_1_id = register_store("Store 1")
    store_2_id = register_store("Store 2")

    switch_to_store(store_1_id)
    add_available_vat_rate(20, "vat20")

    switch_to_store(store_2_id)
    add_available_vat_rate(10, "vat10")

    assert_equal(0, VatRates.available_vat_rates_for_store(store_1_id).where(code: "vat10").count)
    assert_equal(1, VatRates.available_vat_rates_for_store(store_1_id).where(code: "vat20").count)
    assert_equal(1, VatRates.available_vat_rates_for_store(store_2_id).where(code: "vat10").count)
    assert_equal(0, VatRates.available_vat_rates_for_store(store_2_id).where(code: "vat20").count)
  end

  def test_user_cannot_delete_vat_rate_from_another_store
    store_1_id = register_store("Store 1")
    store_2_id = register_store("Store 2")

    add_available_vat_rate(20, "vat20")
    vat_rate_code = "vat20"

    switch_to_store(store_2_id)

    delete available_vat_rates_path, params: { vat_rate_code: vat_rate_code }

    assert_redirected_to available_vat_rates_path
    follow_redirect!
    assert_select "#alert", text: /does not exist/
  end

  def test_user_can_delete_vat_rate_from_their_own_store
    store_1_id = register_store("Store 1")

    add_available_vat_rate(20, "vat20")

    delete available_vat_rates_path, params: { vat_rate_code: "vat20" }

    assert_redirected_to available_vat_rates_path
    follow_redirect!
    assert_select "td", text: "vat20", count: 0
  end

  private

  def switch_to_store(store_id)
    cookies[:current_store_id] = store_id
  end
end
