module ClientInbox
  class NotAuthorized < StandardError; end

  class Message < ApplicationRecord
    self.table_name = 'client_inbox_messages'
  end

  def self.authorize(client_id, message_id)
    raise NotAuthorized unless Message.exists?(client_uid: client_id, id: message_id)
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateMessage.new, to: [Communication::MessageSent])
      event_store.subscribe(ReadMessage.new, to: [Communication::MessageRead])
    end
  end

  class CreateMessage
    def call(event)
      Message.create(
        client_uid: event.data.fetch(:receiver_id),
        title: event.data.fetch(:message)
      )
    end
  end

  class ReadMessage
    def call(event)
      message = Message.find_by(id: event.data.fetch(:message_id))
      message.update(read: true)
      message.save
    end
  end
end