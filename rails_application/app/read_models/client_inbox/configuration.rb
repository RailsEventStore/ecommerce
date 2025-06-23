module ClientInbox

  class Message < ApplicationRecord
    self.table_name = 'client_inbox_messages'
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateMessage.new, to: [Communication::MessageSent])
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
end