require_relative "test_helper"

module Communication
  class SendingMessageTest < Test
    cover "Communication*"

    def test_happy_path
      assert_events(message_stream,
                    message_sent_event,
                    message_read_event) do
        send_message
        read_message
      end
    end

    private

    def message_stream
      "Communication::Message$#{message_id}"
    end

    def message_sent_event
      MessageSent.new(
        data: {
          message_id: message_id,
          receiver_id: receiver_id,
          message: message_content
        }
      )
    end

    def message_read_event
      MessageRead.new(
        data: {
          message_id: message_id
        }
      )
    end
  end
end

