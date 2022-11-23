module Customers
  class PromoteToVip < Infra::EventHandler
    def call(event)
      promote_to_vip(event)
    end

    private
    def promote_to_vip(event)
      find(event.data.fetch(:customer_id)).update(vip: true)
    end

    def find(customer_id)
      Customer.where(id: customer_id).first
    end

  end
end
