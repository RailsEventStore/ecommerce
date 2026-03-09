require "test_helper"

module Contacts
  class ContactsTest < InMemoryRESTestCase
    cover "Contacts*"

    def test_contact_created_on_registration
      register_contact(contact_id, "John Doe")

      assert_equal(1, Contacts.all.count)
      assert_equal("John Doe", Contacts.find_by_uid(contact_id).name)
    end

    def test_multiple_contacts
      register_contact(contact_id, "John Doe")
      register_contact(other_contact_id, "Jane Doe")

      assert_equal(2, Contacts.all.count)
      assert_equal(["John Doe", "Jane Doe"], Contacts.all.map(&:name))
    end

    def test_email_set
      register_contact(contact_id, "John Doe")
      register_contact(other_contact_id, "Jane Doe")
      set_email(contact_id, "john@example.com")

      assert_equal("john@example.com", Contacts.find_by_uid(contact_id).email)
      assert_nil(Contacts.find_by_uid(other_contact_id).email)
    end

    def test_phone_set
      register_contact(contact_id, "John Doe")
      register_contact(other_contact_id, "Jane Doe")
      set_phone(contact_id, "+1234567890")

      assert_equal("+1234567890", Contacts.find_by_uid(contact_id).phone)
      assert_nil(Contacts.find_by_uid(other_contact_id).phone)
    end

    def test_linkedin_url_set
      register_contact(contact_id, "John Doe")
      register_contact(other_contact_id, "Jane Doe")
      set_linkedin_url(contact_id, "https://linkedin.com/in/johndoe")

      assert_equal("https://linkedin.com/in/johndoe", Contacts.find_by_uid(contact_id).linkedin_url)
      assert_nil(Contacts.find_by_uid(other_contact_id).linkedin_url)
    end

    def test_assign_to_company
      register_company(company_id, "Arkency")
      register_contact(contact_id, "John Doe")
      register_contact(other_contact_id, "Jane Doe")
      assign_to_company(contact_id, company_id)

      assert_equal(company_id, Contacts.find_by_uid(contact_id).company_uid)
      assert_nil(Contacts.find_by_uid(other_contact_id).company_uid)
    end

    private

    def company_id
      @company_id ||= SecureRandom.uuid
    end

    def contact_id
      @contact_id ||= SecureRandom.uuid
    end

    def other_contact_id
      @other_contact_id ||= SecureRandom.uuid
    end

    def register_contact(uid, name)
      event_store.publish(Crm::ContactRegistered.new(data: { contact_id: uid, name: name }))
    end

    def set_email(uid, email)
      event_store.publish(Crm::ContactEmailSet.new(data: { contact_id: uid, email: email }))
    end

    def set_phone(uid, phone)
      event_store.publish(Crm::ContactPhoneSet.new(data: { contact_id: uid, phone: phone }))
    end

    def set_linkedin_url(uid, linkedin_url)
      event_store.publish(Crm::ContactLinkedinUrlSet.new(data: { contact_id: uid, linkedin_url: linkedin_url }))
    end

    def register_company(uid, name)
      event_store.publish(Crm::CompanyRegistered.new(data: { company_id: uid, name: name }))
    end

    def assign_to_company(uid, company_uid)
      event_store.publish(Crm::ContactAssignedToCompany.new(data: { position_id: SecureRandom.uuid, contact_id: uid, company_id: company_uid }))
    end
  end
end
