require "test_helper"

class PoliciesTest < InMemoryRESIntegrationTestCase
  def test_accepted_offer_shows_up_as_issued_policy
    go_through_underwriting(application_id)

    get "/policies"
    assert_select("td", "$50.00")
    assert_select("td", "issued")
  end

  def test_paying_premium_activates_policy
    go_through_underwriting(application_id)

    post "/policies/#{application_id}/pay_premium"
    follow_redirect!

    assert_select("td", "active")
  end

  def test_active_policy_can_be_terminated
    go_through_underwriting(application_id)
    post "/policies/#{application_id}/pay_premium"

    post "/policies/#{application_id}/terminate"
    follow_redirect!

    assert_select("td", "terminated")
  end

  private

  def application_id
    @application_id ||= SecureRandom.uuid
  end

  def go_through_underwriting(id)
    post "/applications", params: { application_id: id, coverage_amount: "1000" }
    post "/applications/#{id}/evaluate_risk", params: { risk_class: "standard" }
    post "/applications/#{id}/calculate_premium"
    post "/applications/#{id}/accept_offer"
  end
end
