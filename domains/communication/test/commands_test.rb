require_relative "test_helper"

module Communication
  class CommandsTest < Test
    cover "Communication*"

    MESSAGE_ID = "123e4567-e89b-42d3-a456-426614174000"
    RECEIVER_ID = "223e4567-e89b-42d3-a456-426614174000"

    def test_exposes_attributes
      command = SendMessage.new(MESSAGE_ID, RECEIVER_ID, "Hello")

      assert_equal(MESSAGE_ID, command.message_id)
      assert_equal(RECEIVER_ID, command.receiver_id)
      assert_equal("Hello", command.message)
      assert_equal(MESSAGE_ID, ReadMessage.new(MESSAGE_ID).message_id)
    end

    def test_rejects_invalid_message_id
      message_id_constructors.each do |constructor|
        assert_raises(Infra::Command::Invalid) do
          constructor.call("not-a-uuid")
        end

        assert_raises(Infra::Command::Invalid) do
          constructor.call(Object.new)
        end

        assert_raises(Infra::Command::Invalid) do
          constructor.call("123e4567-e89b-12d3-a456-426614174000")
        end

        assert_raises(Infra::Command::Invalid) do
          constructor.call("123e4567-e89b-42d3-7456-426614174000")
        end
      end
    end

    def test_rejects_invalid_receiver_id
      assert_raises(Infra::Command::Invalid) do
        SendMessage.new(MESSAGE_ID, "not-a-uuid", "Hello")
      end
    end

    def test_rejects_invalid_message
      assert_raises(Infra::Command::Invalid) do
        SendMessage.new(MESSAGE_ID, RECEIVER_ID, Object.new)
      end
    end

    def test_accepts_string_subclass
      message = Class.new(String).new("Hello")

      assert_equal(message, SendMessage.new(MESSAGE_ID, RECEIVER_ID, message).message)
    end

    private

    def message_id_constructors
      [
        ->(message_id) { SendMessage.new(message_id, RECEIVER_ID, "Hello") },
        ->(message_id) { ReadMessage.new(message_id) }
      ]
    end
  end
end
