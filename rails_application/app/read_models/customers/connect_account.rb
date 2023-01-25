module Customers
  class ConnectAccount < Infra::EventHandler
    def call(event)
      find(event.data.fetch(:client_id)).update(account_id: event.data.fetch(:account_id))
    end

    private

    def find(customer_id)
      Customer.where(id: customer_id).first
    end
  end
end
