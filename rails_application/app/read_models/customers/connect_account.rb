module Customers
  class ConnectAccount
    def call(event)
      Customer.find_or_create_by(id: event.data.fetch(:client_id)).update(account_id: event.data.fetch(:account_id))
    end
  end
end
