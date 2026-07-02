module Accounts
  class Account < ApplicationRecord
    self.table_name = "accounts"
  end
  private_constant :Account

  def self.handle_for(account_id)
    Account.find_by(account_id: account_id)&.handle
  end

  class CreateAccount
    def call(event)
      Account.create!(account_id: event.data.fetch(:account_id))
    end
  end

  class SetHandle
    def call(event)
      Account.find_by!(account_id: event.data.fetch(:account_id)).update!(handle: event.data.fetch(:login))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateAccount.new, to: [::Authentication::AccountRegistered])
      event_store.subscribe(SetHandle.new, to: [::Authentication::LoginSet])
    end
  end
end
