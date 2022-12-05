module Orders
  class RegisterProduct < Infra::EventHandler
    def call(event)
      Product.create(uid: event.data.fetch(:product_id))

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end

