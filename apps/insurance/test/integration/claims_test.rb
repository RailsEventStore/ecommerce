require "test_helper"

class ClaimsTest < InMemoryRESIntegrationTestCase
  def test_reported_damage_is_listed
    issue_active_policy(policy_id)

    report_loss(claim_id, policy_id, "Flooded kitchen")

    get "/claims"
    assert_select("td", "Flooded kitchen")
    assert_select("td", "reported")
  end

  def test_assessed_loss_on_active_policy_is_settled_automatically
    issue_active_policy(policy_id)
    report_loss(claim_id, policy_id, "Flooded kitchen")

    post "/claims/#{claim_id}/assess", params: { amount: "300" }
    follow_redirect!

    assert_select("td", "$300.00")
    assert_select("td", "settled")
  end

  def test_assessed_loss_without_active_policy_is_not_settled
    issue_policy_without_payment(policy_id)
    report_loss(claim_id, policy_id, "Flooded kitchen")

    post "/claims/#{claim_id}/assess", params: { amount: "300" }
    follow_redirect!

    assert_select("td", "assessed")
  end

  def test_settlement_arrives_once_premium_is_paid_after_assessment
    issue_policy_without_payment(policy_id)
    report_loss(claim_id, policy_id, "Flooded kitchen")
    post "/claims/#{claim_id}/assess", params: { amount: "300" }

    post "/policies/#{policy_id}/pay_premium"

    get "/claims"
    assert_select("td", "settled")
  end

  private

  def policy_id
    @policy_id ||= SecureRandom.uuid
  end

  def claim_id
    @claim_id ||= SecureRandom.uuid
  end

  def issue_policy_without_payment(id)
    post "/applications", params: { application_id: id, coverage_amount: "1000" }
    post "/applications/#{id}/evaluate_risk", params: { risk_class: "standard" }
    post "/applications/#{id}/calculate_premium"
    post "/applications/#{id}/accept_offer"
  end

  def issue_active_policy(id)
    issue_policy_without_payment(id)
    post "/policies/#{id}/pay_premium"
  end

  def report_loss(cid, pid, description)
    post "/claims", params: { claim_id: cid, policy_id: pid, description: description }
  end
end
