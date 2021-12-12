module Taxes
  class SetVatRateHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Product, cmd.product_id) do |product|
        product.set_vat_rate(cmd.vat_rate)
      end
    end
  end

  class DetermineVatRateHandler
    def initialize(event_store)
      @catalog = VatRateCatalog.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      order_id = cmd.order_id
      product_id = cmd.product_id
      vat_rate = catalog.vat_rate_for(product_id)
      return unless vat_rate
      event = VatRateDetermined.new(data: { order_id: order_id, product_id: product_id, vat_rate: vat_rate })
      event_store.publish(event, stream_name: stream_name(order_id))
    end

    private

    attr_reader :catalog, :event_store

    def stream_name(order_id)
      "Taxes::Order$#{order_id}"
    end
  end
end