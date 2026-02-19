require "test_helper"

class ContactsIntegrationTest < InMemoryRESIntegrationTestCase
  def test_list_contacts
    get "/contacts"
    assert_response(:success)
  end

  def test_new_contact_form
    get "/contacts/new"
    assert_response(:success)
  end

  def test_create_contact
    post "/contacts", params: { contact: { name: "John Doe" } }
    follow_redirect!
    assert_select("td", "John Doe")
  end

  def test_create_contact_with_all_fields
    post "/contacts", params: {
      contact: {
        name: "John Doe",
        email: "john@example.com",
        phone: "+1234567890",
        linkedin_url: "https://linkedin.com/in/johndoe"
      }
    }
    follow_redirect!
    assert_select("td", "John Doe")
    assert_select("td", "john@example.com")
  end

  def test_show_contact
    contact_id = create_contact("John Doe")

    get "/contacts/#{contact_id}"
    assert_response(:success)
    assert_select("h1", "John Doe")
  end

  def test_edit_contact
    contact_id = create_contact("John Doe")

    get "/contacts/#{contact_id}/edit"
    assert_response(:success)
  end

  def test_update_contact
    contact_id = create_contact("John Doe")

    patch "/contacts/#{contact_id}", params: {
      contact: {
        email: "john@example.com",
        phone: "+1234567890",
        linkedin_url: "https://linkedin.com/in/johndoe"
      }
    }
    follow_redirect!
    assert_select("dd", "john@example.com")
    assert_select("dd", "+1234567890")
    assert_select("dd", "https://linkedin.com/in/johndoe")
  end

  def test_assign_contact_to_company
    company_id = create_company("Arkency")
    contact_id = create_contact("Alice")

    patch "/contacts/#{contact_id}", params: {
      contact: { company_id: company_id }
    }
    follow_redirect!
    assert_select("dd", "Arkency")
  end

  private

  def create_contact(name)
    post "/contacts", params: { contact: { name: name } }
    follow_redirect!
    Contacts.all.last.uid
  end

  def create_company(name)
    post "/companies", params: { company: { name: name } }
    follow_redirect!
    Companies.all.last.uid
  end
end
