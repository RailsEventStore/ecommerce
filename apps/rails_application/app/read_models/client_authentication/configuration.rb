module ClientAuthentication
  class Account < ApplicationRecord
    self.table_name = "accounts"
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateAccount.new, to: [Authentication::AccountConnectedToClient])
      event_store.subscribe(SetPassword.new, to: [Authentication::PasswordHashSet])
    end
  end
end
