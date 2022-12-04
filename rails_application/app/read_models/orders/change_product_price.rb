module Orders
  class ChangeProductPrice < ReadModel
    def call(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(price: event.data.fetch(:price))

      link_event_to_stream(event)
    end
  end
end
