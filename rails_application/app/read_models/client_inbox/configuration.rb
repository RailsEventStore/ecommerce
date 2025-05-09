module ClientInbox

  class Message < ApplicationRecord
    self.table_name = 'client_inbox_messages'
  end

  class Configuration
    def call(event_store)
    end
  end
end