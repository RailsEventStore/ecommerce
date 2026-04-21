module Customers
  class PromoteToVip
    def call(event)
      Customer.find_by(id: event.data.fetch(:customer_id)).update(vip: true)
    end
  end
end
