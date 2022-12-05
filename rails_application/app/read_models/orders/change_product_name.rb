module Orders
  class ChangeProductName < Infra::EventHandler
    def call(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(
        name: event.data.fetch(:name)
      )

      Rails.configuration.read_model.link_event_to_stream(event)
    end
  end
end

