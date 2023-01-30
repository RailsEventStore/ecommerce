module ClientAuthentication
  class Account < ApplicationRecord
    self.table_name = "accounts"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateAccount, to: [Authentication::AccountConnectedToClient])
    end
  end
end
