require "test_helper"

module Companies
  class CompaniesTest < InMemoryRESTestCase
    cover "Companies*"

    def test_company_created_on_registration
      register_company(company_id, "Arkency")

      assert_equal(1, Companies.all.count)
      assert_equal("Arkency", Companies.find_by_uid(company_id).name)
    end

    def test_multiple_companies
      register_company(company_id, "Arkency")
      register_company(other_company_id, "Acme Corp")

      assert_equal(2, Companies.all.count)
      assert_equal(["Arkency", "Acme Corp"], Companies.all.map(&:name))
    end

    def test_linkedin_url_set
      register_company(company_id, "Arkency")
      register_company(other_company_id, "Acme Corp")
      set_linkedin_url(company_id, "https://linkedin.com/company/arkency")

      assert_equal("https://linkedin.com/company/arkency", Companies.find_by_uid(company_id).linkedin_url)
      assert_nil(Companies.find_by_uid(other_company_id).linkedin_url)
    end

    private

    def company_id
      @company_id ||= SecureRandom.uuid
    end

    def other_company_id
      @other_company_id ||= SecureRandom.uuid
    end

    def register_company(uid, name)
      event_store.publish(Crm::CompanyRegistered.new(data: { company_id: uid, name: name }))
    end

    def set_linkedin_url(uid, linkedin_url)
      event_store.publish(Crm::CompanyLinkedinUrlSet.new(data: { company_id: uid, linkedin_url: linkedin_url }))
    end
  end
end
