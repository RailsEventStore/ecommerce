require_relative "test_helper"

module Crm
  class CompanyTest < Test
    cover "Crm*"

    def test_register_company
      uid = SecureRandom.uuid
      assert_events("Crm::Company$#{uid}", CompanyRegistered.new(data: { company_id: uid, name: "Arkency" })) do
        register_company(uid, "Arkency")
      end
    end

    def test_cannot_register_same_company_twice
      uid = SecureRandom.uuid
      register_company(uid, "Arkency")

      assert_raises(Company::AlreadyRegistered) do
        register_company(uid, "Arkency")
      end
    end

    def test_set_company_linkedin_url
      uid = SecureRandom.uuid
      assert_events(
        "Crm::Company$#{uid}",
        CompanyRegistered.new(data: { company_id: uid, name: "Arkency" }),
        CompanyLinkedinUrlSet.new(data: { company_id: uid, linkedin_url: "https://linkedin.com/company/arkency" })
      ) do
        register_company(uid, "Arkency")
        set_company_linkedin_url(uid, "https://linkedin.com/company/arkency")
      end
    end

    def test_cannot_set_linkedin_url_for_nonexistent_company
      uid = SecureRandom.uuid

      assert_raises(Company::NotFound) do
        set_company_linkedin_url(uid, "https://linkedin.com/company/arkency")
      end
    end

    private

    def register_company(uid, name)
      run_command(RegisterCompany.new(company_id: uid, name: name))
    end

    def set_company_linkedin_url(uid, linkedin_url)
      run_command(SetCompanyLinkedinUrl.new(company_id: uid, linkedin_url: linkedin_url))
    end
  end
end
