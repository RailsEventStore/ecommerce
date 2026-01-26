module ProductCatalog

  class Naming
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(product_named_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def product_named_event(cmd)
      ProductNamed.new(
        data: {
          product_id: cmd.product_id,
          name: cmd.name
        }
      )
    end

    def stream_name(cmd)
      "Catalog::ProductName$#{cmd.product_id}"
    end
  end
end
