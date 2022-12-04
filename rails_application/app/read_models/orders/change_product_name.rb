module Orders
  class ChangeProductName < ReadModel
    def call(event)
      Product.find_by_uid(event.data.fetch(:product_id)).update(
        name: event.data.fetch(:name)
      )

      link_event_to_stream(event)
    end
  end
end

