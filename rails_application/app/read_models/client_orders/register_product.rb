module ClientOrders
  class RegisterProduct < Infra::EventHandler
    def call(event)
      ApplicationRecord.with_advisory_lock(event.data.fetch(:product_id)) do
        Product.find_or_create_by(uid: event.data.fetch(:product_id))
      end
    end
  end
end

