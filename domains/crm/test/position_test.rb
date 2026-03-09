require_relative "test_helper"

module Crm
  class PositionTest < Test
    cover "Crm*"

    def test_assign_contact_to_company
      position_id = SecureRandom.uuid
      contact_id = SecureRandom.uuid
      company_id = SecureRandom.uuid

      assert_events(
        "Crm::Position$#{position_id}",
        ContactAssignedToCompany.new(data: { position_id: position_id, contact_id: contact_id, company_id: company_id })
      ) do
        assign_contact_to_company(position_id, contact_id, company_id)
      end
    end

    def test_cannot_assign_contact_to_company_twice
      position_id = SecureRandom.uuid
      contact_id = SecureRandom.uuid
      company_id = SecureRandom.uuid
      assign_contact_to_company(position_id, contact_id, company_id)

      assert_raises(Position::AlreadyCreated) do
        assign_contact_to_company(position_id, contact_id, company_id)
      end
    end

    private

    def assign_contact_to_company(position_id, contact_id, company_id)
      run_command(AssignContactToCompany.new(position_id: position_id, contact_id: contact_id, company_id: company_id))
    end
  end
end
