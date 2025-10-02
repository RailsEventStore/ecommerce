module ProductCatalog
  class Archivization
    def initialize(event_store)
      @event_store = event_store
    end

    def call(command)
      @event_store.publish(
        ProductArchived.new(
          data: { product_id: command.product_id }
        ),
        stream_name: "ProductCatalog$#{command.product_id}"
      )
    end
  end
end