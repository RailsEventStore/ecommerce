require_relative "test_helper"

module Crm
  class DealPartyTest < Test
    cover "Crm*"

    def test_add_company_to_deal
      deal_party_id = SecureRandom.uuid
      deal_id = SecureRandom.uuid
      company_id = SecureRandom.uuid

      assert_events(
        "Crm::DealParty$#{deal_party_id}",
        CompanyAssignedToDeal.new(data: { deal_party_id: deal_party_id, deal_id: deal_id, company_id: company_id })
      ) do
        add_company_to_deal(deal_party_id, deal_id, company_id)
      end
    end

    def test_add_contact_to_deal
      deal_party_id = SecureRandom.uuid
      deal_id = SecureRandom.uuid
      contact_id = SecureRandom.uuid

      assert_events(
        "Crm::DealParty$#{deal_party_id}",
        ContactAssignedToDeal.new(data: { deal_party_id: deal_party_id, deal_id: deal_id, contact_id: contact_id })
      ) do
        add_contact_to_deal(deal_party_id, deal_id, contact_id)
      end
    end

    def test_cannot_add_company_to_deal_twice
      deal_party_id = SecureRandom.uuid
      deal_id = SecureRandom.uuid
      company_id = SecureRandom.uuid
      add_company_to_deal(deal_party_id, deal_id, company_id)

      assert_raises(DealParty::AlreadyCreated) do
        add_company_to_deal(deal_party_id, deal_id, company_id)
      end
    end

    def test_cannot_add_contact_to_deal_twice
      deal_party_id = SecureRandom.uuid
      deal_id = SecureRandom.uuid
      contact_id = SecureRandom.uuid
      add_contact_to_deal(deal_party_id, deal_id, contact_id)

      assert_raises(DealParty::AlreadyCreated) do
        add_contact_to_deal(deal_party_id, deal_id, contact_id)
      end
    end

    private

    def add_company_to_deal(deal_party_id, deal_id, company_id)
      run_command(AssignCompanyToDeal.new(deal_party_id: deal_party_id, deal_id: deal_id, company_id: company_id))
    end

    def add_contact_to_deal(deal_party_id, deal_id, contact_id)
      run_command(AssignContactToDeal.new(deal_party_id: deal_party_id, deal_id: deal_id, contact_id: contact_id))
    end
  end
end
