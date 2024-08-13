module Taxes
  VatRateAlreadyExists = Class.new(StandardError)
  class SetVatRateHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @catalog = VatRateCatalog.new(event_store)
    end

    def call(cmd)
      @repository.with_aggregate(Product, cmd.product_id) do |product|
        product.set_vat_rate(cmd.vat_rate, @catalog)
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

  class AddAvailableVatRateHandler
    def initialize(event_store)
      @catalog = VatRateCatalog.new(event_store)
      @event_store = event_store
    end

    def call(cmd)
      raise VatRateAlreadyExists if catalog.vat_rate_available?(cmd.vat_rate.code)

      event_store.publish(available_vat_rate_added_event(cmd), stream_name: stream_name(cmd))
    end

    private

    attr_reader :event_store, :catalog

    def available_vat_rate_added_event(cmd)
      AvailableVatRateAdded.new(
        data: {
          available_vat_rate_id: cmd.available_vat_rate_id,
          vat_rate: cmd.vat_rate
        }
      )
    end

    def stream_name(cmd)
      "Taxes::AvailableVatRate$#{cmd.vat_rate.code}"
    end
  end
end
