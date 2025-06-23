require_relative "test_helper"

module Communication
  class SendingMessageTest < Test
    cover "Communication*"

    def test_happy_path
      expected_event = MessageSent.new(data: {message_id: message_id, receiver_id: receiver_id, message: message_content})
      assert_events("Communication::Message$#{message_id}", expected_event) do
        send_message
      end
    end
  end
end

