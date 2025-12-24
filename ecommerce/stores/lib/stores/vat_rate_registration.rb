module Stores
  class VatRateRegistration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(vat_rate_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def vat_rate_registered_event(cmd)
      VatRateRegistered.new(
        data: {
          store_id: cmd.store_id,
          vat_rate_id: cmd.vat_rate_id,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
