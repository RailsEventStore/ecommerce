module ProductCatalog

  class Moderation
    def initialize(event_store, name_moderation)
      @event_store = event_store
      @name_moderation = name_moderation
    end

    def call(cmd)
      @event_store.publish(moderation_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def moderation_event(cmd)
      if @name_moderation.allowed?(cmd.name)
        ProductNameApproved.new(data: { product_id: cmd.product_id, name: cmd.name })
      else
        ProductNameRejected.new(data: { product_id: cmd.product_id, name: cmd.name })
      end
    end

    def stream_name(cmd)
      "Catalog::ProductName$#{cmd.product_id}"
    end
  end
end
