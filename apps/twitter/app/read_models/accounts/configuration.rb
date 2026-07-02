module Accounts
  class Account < ApplicationRecord
    self.table_name = "accounts"
  end
  private_constant :Account

  def self.handle_for(account_id)
    Account.find_by(account_id: account_id)&.handle
  end

  def self.id_for(handle)
    Account.find_by(handle: handle)&.account_id
  end

  def self.authenticate(handle, password)
    account = Account.find_by(handle: handle)
    return unless account

    account.account_id if BCrypt::Password.new(account.password_hash) == password
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

  class SetPassword
    def call(event)
      Account.find_by!(account_id: event.data.fetch(:account_id)).update!(password_hash: event.data.fetch(:password_hash))
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(CreateAccount.new, to: [::Authentication::AccountRegistered])
      event_store.subscribe(SetHandle.new, to: [::Authentication::LoginSet])
      event_store.subscribe(SetPassword.new, to: [::Authentication::PasswordHashSet])
    end
  end
end
