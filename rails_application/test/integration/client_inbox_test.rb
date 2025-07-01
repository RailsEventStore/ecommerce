require_relative "../test_helper"

class ClientInboxTest < InMemoryRESIntegrationTestCase

  def test_customer_sees_inbox_messages
    customer_id = register_customer
    login(customer_id)
    get "/client/inbox"
    assert_response :success
    assert_select "h1", "Your Inbox"
    assert_message_unread("Welcome to our platform!", /minute ago/)
    message_id = ClientInbox::Message.last.id
    post "/client/inbox/mark_as_read", params: { message_id: message_id }
    follow_redirect!
    assert_message_read("Welcome to our platform!", /minute ago/)
  end

  def test_another_customer_cant_mark_my_message_as_read_even_when_know_the_id
    another_customer_id = register_customer("Another Customer")
    customer_id = register_customer
    login(another_customer_id)
    get "/client/inbox"

    assert_response :success
    assert_select "h1", "Your Inbox"
    assert_message_unread("Welcome to our platform!", /minute ago/)
    other_client_message_id = ClientInbox::Message.find_by(client_uid: customer_id)

    post "/client/inbox/mark_as_read",
         params: { message_id: other_client_message_id }
    assert_response :missing
  end

  private

  def assert_message_unread(title, timestamp)
    assert_select "h3.font-bold.text-gray-900.text-lg.cursor-pointer", 1
    assert_select "h3.font-bold.text-gray-900.text-lg", title
    assert_select "span.text-sm.text-gray-500", timestamp
    assert_select "span.inline-block.h-2.w-2.rounded-full.bg-blue-600"
  end

  def assert_message_read(title, timestamp)
    assert_select "h3.font-bold", false
    assert_select "h3.text-gray-700.text-lg", 1
    assert_select "h3.text-gray-700.text-lg", title
    assert_select "span.text-sm.text-gray-500", timestamp
    assert_select "span.inline-block.h-2.w-2.rounded-full.bg-blue-600", 0
  end

end

