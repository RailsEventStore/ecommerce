module ClientAuthentication
  class CreateAccount < Infra::EventHandler
    def call(event)
      client_id = event.data.fetch(:client_id)
      account_id = event.data.fetch(:account_id)
      Account.find_or_create_by(client_id: client_id, account_id: account_id)
    end
  end
end
