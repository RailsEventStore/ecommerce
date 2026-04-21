require "test_helper"

module ClientInbox
  class HandlersAndFacadeTest < InMemoryTestCase
    cover "ClientInbox*"

    def configure(event_store, _command_bus)
      ClientInbox::Configuration.new.call(event_store)
    end

    def test_create_message_assigns_title_to_receiver
      client_id = SecureRandom.uuid
      other_client_id = SecureRandom.uuid

      publish_message_sent(SecureRandom.uuid, client_id, "Welcome")
      publish_message_sent(SecureRandom.uuid, other_client_id, "Hi there")

      assert_equal(["Welcome"], Message.where(client_uid: client_id).pluck(:title))
      assert_equal(["Hi there"], Message.where(client_uid: other_client_id).pluck(:title))
    end

    def test_read_message_marks_only_matching_message_as_read
      client_id = SecureRandom.uuid
      publish_message_sent(SecureRandom.uuid, client_id, "First")
      publish_message_sent(SecureRandom.uuid, client_id, "Second")

      first = Message.find_by(title: "First")
      second = Message.find_by(title: "Second")

      event_store.publish(Communication::MessageRead.new(data: { message_id: first.id }))

      assert(Message.find(first.id).read)
      refute(Message.find(second.id).read)
    end

    def test_authorize_passes_when_message_belongs_to_client
      client_id = SecureRandom.uuid
      publish_message_sent(SecureRandom.uuid, client_id, "Mine")
      message = Message.find_by(client_uid: client_id)

      assert_nil(ClientInbox.authorize(client_id, message.id))
    end

    def test_authorize_raises_when_message_id_does_not_exist
      client_id = SecureRandom.uuid
      publish_message_sent(SecureRandom.uuid, client_id, "Mine")

      assert_raises(ClientInbox::NotAuthorized) do
        ClientInbox.authorize(client_id, SecureRandom.uuid)
      end
    end

    def test_authorize_raises_when_message_belongs_to_different_client
      client_id = SecureRandom.uuid
      other_client_id = SecureRandom.uuid
      publish_message_sent(SecureRandom.uuid, other_client_id, "Theirs")
      message = Message.find_by(client_uid: other_client_id)

      assert_raises(ClientInbox::NotAuthorized) do
        ClientInbox.authorize(client_id, message.id)
      end
    end

    private

    def publish_message_sent(message_id, receiver_id, message)
      event_store.publish(
        Communication::MessageSent.new(
          data: { message_id: message_id, receiver_id: receiver_id, message: message }
        )
      )
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
