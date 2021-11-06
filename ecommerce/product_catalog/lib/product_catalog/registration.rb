module ProductCatalog
  class Registration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call(cmd)
      events = @cqrs.all_events_from_stream(stream_name(cmd))
      raise Product::AlreadyRegistered unless events.empty?

      @cqrs.publish(product_registered_event(cmd), stream_name(cmd))
    end

    private

    def product_registered_event(cmd)
      ProductRegistered.new(
        data: {
          product_id: cmd.product_id,
          name: cmd.name
        }
      )
    end

    def stream_name(cmd)
      "Catalog::Product$#{cmd.product_id}"
    end
  end
end
