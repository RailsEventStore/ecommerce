require "test_helper"

class CompaniesIntegrationTest < InMemoryRESIntegrationTestCase
  def test_list_companies
    get "/companies"
    assert_response(:success)
  end

  def test_new_company_form
    get "/companies/new"
    assert_response(:success)
  end

  def test_create_company
    post "/companies", params: { company: { name: "Arkency" } }
    follow_redirect!
    assert_select("td", "Arkency")
  end

  def test_create_company_with_linkedin
    post "/companies", params: {
      company: {
        name: "Arkency",
        linkedin_url: "https://linkedin.com/company/arkency"
      }
    }
    follow_redirect!
    assert_select("td", "Arkency")
  end

  def test_show_company
    company_id = create_company("Arkency")

    get "/companies/#{company_id}"
    assert_response(:success)
    assert_select("h1", "Arkency")
  end

  def test_edit_company
    company_id = create_company("Arkency")

    get "/companies/#{company_id}/edit"
    assert_response(:success)
  end

  def test_update_company
    company_id = create_company("Arkency")

    patch "/companies/#{company_id}", params: {
      company: { linkedin_url: "https://linkedin.com/company/arkency" }
    }
    follow_redirect!
    assert_select("dd", "https://linkedin.com/company/arkency")
  end

  private

  def create_company(name)
    post "/companies", params: { company: { name: name } }
    follow_redirect!
    Companies.all.last.uid
  end
end
