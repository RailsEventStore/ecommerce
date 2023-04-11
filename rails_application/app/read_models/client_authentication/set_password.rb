module ClientAuthentication
  class SetPassword < Infra::EventHandler
    def call(event)
      find(event.data.fetch(:account_id)).update(password: event.data.fetch(:password_hash))
    end

    private

    def find(account_id)
      Account.find_or_create_by(account_id: account_id)
    end
  end
end
