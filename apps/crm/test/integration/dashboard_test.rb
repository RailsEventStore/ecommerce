require "test_helper"

class DashboardIntegrationTest < InMemoryRESIntegrationTestCase
  def test_dashboard
    get "/"
    assert_response(:success)
    assert_select("h1", "Dashboard")
  end

  def test_dashboard_shows_counts
    post "/contacts", params: { contact: { name: "Alice" } }
    post "/companies", params: { company: { name: "Arkency" } }
    pipeline_id = create_pipeline("Sales")
    post "/deals", params: { deal: { name: "Big Deal", pipeline_id: pipeline_id } }

    get "/"
    assert_select(".stat-contacts", /1/)
    assert_select(".stat-companies", /1/)
    assert_select(".stat-deals", /1/)
    assert_select(".stat-pipelines", /1/)
  end

  private

  def create_pipeline(name)
    post "/pipelines", params: { pipeline: { name: name } }
    follow_redirect!
    Pipelines.all.last.uid
  end
end
