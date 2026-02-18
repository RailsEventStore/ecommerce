require "test_helper"

class ActivitiesIntegrationTest < InMemoryRESIntegrationTestCase
  def test_list_activities
    get "/activities"
    assert_response(:success)
    assert_select("h1", "Activity Log")
  end

  def test_activities_show_entries
    post "/contacts", params: { contact: { name: "Alice" } }
    post "/companies", params: { company: { name: "Arkency" } }

    get "/activities"
    assert_select("td", "Contact registered: Alice")
    assert_select("td", "Company registered: Arkency")
  end
end
