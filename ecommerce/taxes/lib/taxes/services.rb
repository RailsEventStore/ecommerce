module Taxes
  VatRateAlreadyExists = Class.new(StandardError)
  VatRateNotApplicable = Class.new(StandardError)
  VatRateNotExists = Class.new(StandardError)
  class SetVatRateHandler
    def initialize(event_store)
      @repository = Infra::AggregateRootRepository.new(event_store)
      @catalog = VatRateCatalog.new(event_store)
    end

    def call(cmd)
      vat_rate = @catalog.vat_rate_by_code(cmd.vat_rate_code)
      raise VatRateNotApplicable unless vat_rate
      @repository.with_aggregate(Product, cmd.product_id) do |product|
        product.set_vat_rate(vat_rate)
      end
    end
  end

  class AddAvailableVatRateHandler
    include Infra::Retry

    def initialize(event_store, command_bus)
      @event_store = event_store
      @command_bus = command_bus
    end

    def call(cmd)
      with_retry do
        event = last_available_vat_rate_event(cmd.vat_rate.code)
        raise VatRateAlreadyExists if event.instance_of?(AvailableVatRateAdded)

        expected_version = event ? event_store.position_in_stream(event.event_id, stream_name(cmd)) : -1
        event_store.publish(available_vat_rate_added_event(cmd), stream_name: stream_name(cmd), expected_version: expected_version)
        command_bus.call(Stores::RegisterVatRate.new(store_id: cmd.store_id, vat_rate_id: cmd.available_vat_rate_id))
      end
    end

    private

    attr_reader :event_store, :command_bus

    def last_available_vat_rate_event(vat_rate_code)
      event_store
        .read
        .stream("Taxes::AvailableVatRate$#{vat_rate_code}")
        .last
    end

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

  class RemoveAvailableVatRateHandler
    include Infra::Retry

    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      with_retry do
        event = last_available_vat_rate_event(cmd.vat_rate_code)
        raise VatRateNotExists unless event.instance_of?(AvailableVatRateAdded)

        event_store.publish(
          available_vat_rate_removed_event(cmd),
          stream_name: stream_name(cmd),
          expected_version: event_store.position_in_stream(event.event_id, stream_name(cmd))
        )
      end
    end

    private

    attr_reader :event_store

    def last_available_vat_rate_event(vat_rate_code)
      event_store
        .read
        .stream("Taxes::AvailableVatRate$#{vat_rate_code}")
        .last
    end

    def available_vat_rate_removed_event(cmd)
      AvailableVatRateRemoved.new(data: { vat_rate_code: cmd.vat_rate_code })
    end

    def stream_name(cmd)
      "Taxes::AvailableVatRate$#{cmd.vat_rate_code}"
    end
  end
end
