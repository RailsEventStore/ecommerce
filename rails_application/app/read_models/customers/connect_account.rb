module Customers
  class ConnectAccount < Infra::EventHandler
    def call(event)
      ApplicationRecord.with_advisory_lock(event.data.fetch(:client_id)) do
        Customer.find_or_create_by(id: event.data.fetch(:client_id)).update(account_id: event.data.fetch(:account_id))
      end
    end
  end
end
