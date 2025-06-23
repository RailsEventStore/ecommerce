require_relative "../test_helper"

class ClientInboxTest < InMemoryRESIntegrationTestCase
  def test_customer_sees_inbox_messages
    customer_id = register_customer("Test Customer")
    login(customer_id)
    get "/client/inbox"
    
    assert_response :success
    assert_select "h1", "Your Inbox"
    assert_message("Welcome to our platform!", /minute ago/)
  end

  private

  def assert_message(title, timestamp)
    assert_select "h3.font-bold.text-gray-900.text-lg", 1
    assert_select "h3.font-bold.text-gray-900.text-lg", title
    assert_select "span.text-sm.text-gray-500", timestamp
    assert_select "span.inline-block.h-2.w-2.rounded-full.bg-blue-600"
  end

end

