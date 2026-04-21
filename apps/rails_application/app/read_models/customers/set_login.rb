module Customers
  class SetLogin
    def call(event)
      Customer.find_by(account_id: event.data.fetch(:account_id)).update(login: event.data.fetch(:login))
    end
  end
end
