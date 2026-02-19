require_relative "test_helper"

module Crm
  class ContactTest < Test
    cover "Crm*"

    def test_register_contact
      uid = SecureRandom.uuid
      assert_events("Crm::Contact$#{uid}", ContactRegistered.new(data: { contact_id: uid, name: "John Doe" })) do
        register_contact(uid, "John Doe")
      end
    end

    def test_cannot_register_same_contact_twice
      uid = SecureRandom.uuid
      register_contact(uid, "John Doe")

      assert_raises(Contact::AlreadyRegistered) do
        register_contact(uid, "John Doe")
      end
    end

    def test_set_contact_email
      uid = SecureRandom.uuid
      assert_events(
        "Crm::Contact$#{uid}",
        ContactRegistered.new(data: { contact_id: uid, name: "John Doe" }),
        ContactEmailSet.new(data: { contact_id: uid, email: "john@example.com" })
      ) do
        register_contact(uid, "John Doe")
        set_contact_email(uid, "john@example.com")
      end
    end

    def test_cannot_set_email_for_nonexistent_contact
      uid = SecureRandom.uuid

      assert_raises(Contact::NotFound) do
        set_contact_email(uid, "john@example.com")
      end
    end

    def test_set_contact_phone
      uid = SecureRandom.uuid
      assert_events(
        "Crm::Contact$#{uid}",
        ContactRegistered.new(data: { contact_id: uid, name: "John Doe" }),
        ContactPhoneSet.new(data: { contact_id: uid, phone: "+1234567890" })
      ) do
        register_contact(uid, "John Doe")
        set_contact_phone(uid, "+1234567890")
      end
    end

    def test_cannot_set_phone_for_nonexistent_contact
      uid = SecureRandom.uuid

      assert_raises(Contact::NotFound) do
        set_contact_phone(uid, "+1234567890")
      end
    end

    def test_set_contact_linkedin_url
      uid = SecureRandom.uuid
      assert_events(
        "Crm::Contact$#{uid}",
        ContactRegistered.new(data: { contact_id: uid, name: "John Doe" }),
        ContactLinkedinUrlSet.new(data: { contact_id: uid, linkedin_url: "https://linkedin.com/in/johndoe" })
      ) do
        register_contact(uid, "John Doe")
        set_contact_linkedin_url(uid, "https://linkedin.com/in/johndoe")
      end
    end

    def test_cannot_set_linkedin_url_for_nonexistent_contact
      uid = SecureRandom.uuid

      assert_raises(Contact::NotFound) do
        set_contact_linkedin_url(uid, "https://linkedin.com/in/johndoe")
      end
    end

    def test_assign_contact_to_company
      uid = SecureRandom.uuid
      company_id = SecureRandom.uuid
      register_company(company_id, "Arkency")

      assert_events(
        "Crm::Contact$#{uid}",
        ContactRegistered.new(data: { contact_id: uid, name: "John Doe" }),
        ContactAssignedToCompany.new(data: { contact_id: uid, company_id: company_id })
      ) do
        register_contact(uid, "John Doe")
        assign_contact_to_company(uid, company_id)
      end
    end

    def test_cannot_assign_nonexistent_contact_to_company
      uid = SecureRandom.uuid
      company_id = SecureRandom.uuid
      register_company(company_id, "Arkency")

      assert_raises(Contact::NotFound) do
        assign_contact_to_company(uid, company_id)
      end
    end

    def test_cannot_assign_contact_to_nonexistent_company
      uid = SecureRandom.uuid
      company_id = SecureRandom.uuid
      register_contact(uid, "John Doe")

      assert_raises(Company::NotFound) do
        assign_contact_to_company(uid, company_id)
      end
    end

    def test_assign_contact_to_same_company_is_noop
      uid = SecureRandom.uuid
      company_id = SecureRandom.uuid
      register_company(company_id, "Arkency")

      assert_events(
        "Crm::Contact$#{uid}",
        ContactRegistered.new(data: { contact_id: uid, name: "John Doe" }),
        ContactAssignedToCompany.new(data: { contact_id: uid, company_id: company_id })
      ) do
        register_contact(uid, "John Doe")
        assign_contact_to_company(uid, company_id)
        assign_contact_to_company(uid, company_id)
      end
    end

    def test_can_reassign_contact_to_different_company
      uid = SecureRandom.uuid
      company_id = SecureRandom.uuid
      other_company_id = SecureRandom.uuid
      register_company(company_id, "Arkency")
      register_company(other_company_id, "Acme")

      assert_events(
        "Crm::Contact$#{uid}",
        ContactRegistered.new(data: { contact_id: uid, name: "John Doe" }),
        ContactAssignedToCompany.new(data: { contact_id: uid, company_id: company_id }),
        ContactAssignedToCompany.new(data: { contact_id: uid, company_id: other_company_id })
      ) do
        register_contact(uid, "John Doe")
        assign_contact_to_company(uid, company_id)
        assign_contact_to_company(uid, other_company_id)
      end
    end

    private

    def register_contact(uid, name)
      run_command(RegisterContact.new(contact_id: uid, name: name))
    end

    def set_contact_email(uid, email)
      run_command(SetContactEmail.new(contact_id: uid, email: email))
    end

    def set_contact_phone(uid, phone)
      run_command(SetContactPhone.new(contact_id: uid, phone: phone))
    end

    def set_contact_linkedin_url(uid, linkedin_url)
      run_command(SetContactLinkedinUrl.new(contact_id: uid, linkedin_url: linkedin_url))
    end

    def assign_contact_to_company(uid, company_id)
      run_command(AssignContactToCompany.new(contact_id: uid, company_id: company_id))
    end

    def register_company(uid, name)
      run_command(RegisterCompany.new(company_id: uid, name: name))
    end
  end
end
