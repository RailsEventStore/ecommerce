module ProductCatalog
  AlreadyRegistered = Class.new(StandardError)

  class Registration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      events = all_events_from_stream(stream_name(cmd))
      raise AlreadyRegistered unless events.empty?

      @event_store.publish(product_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def all_events_from_stream(name)
      @event_store.read.stream(name).to_a
    end

    def product_registered_event(cmd)
      ProductRegistered.new(
        data: {
          product_id: cmd.product_id,
        }
      )
    end

    def stream_name(cmd)
      "Catalog::Product$#{cmd.product_id}"
    end
  end
end
