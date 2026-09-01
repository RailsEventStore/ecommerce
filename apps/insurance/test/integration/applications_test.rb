require "test_helper"

class ApplicationsTest < InMemoryRESIntegrationTestCase
  def test_list_applications
    get "/applications"
    assert_response :success
  end

  def test_submit_application
    submit_application(application_id, "1000")

    get "/applications"
    assert_select("td", "$1,000.00")
    assert_select("td", "submitted")
  end

  def test_evaluate_risk
    submit_application(application_id, "1000")

    post "/applications/#{application_id}/evaluate_risk", params: { risk_class: "standard" }
    follow_redirect!

    assert_select("td", "standard")
    assert_select("td", "risk evaluated")
  end

  def test_calculate_premium
    submit_application(application_id, "1000")
    post "/applications/#{application_id}/evaluate_risk", params: { risk_class: "standard" }

    post "/applications/#{application_id}/calculate_premium"
    follow_redirect!

    assert_select("td", "$50.00")
    assert_select("td", "priced")
  end

  def test_accept_offer
    submit_application(application_id, "1000")
    post "/applications/#{application_id}/evaluate_risk", params: { risk_class: "standard" }
    post "/applications/#{application_id}/calculate_premium"

    post "/applications/#{application_id}/accept_offer"
    follow_redirect!

    assert_select("td", "accepted")
  end

  private

  def application_id
    @application_id ||= SecureRandom.uuid
  end

  def submit_application(id, coverage_amount)
    post "/applications", params: { application_id: id, coverage_amount: coverage_amount }
    follow_redirect!
  end
end
