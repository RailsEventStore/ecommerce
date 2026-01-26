module Stores
  class InvoiceRegistration
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(invoice_registered_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def invoice_registered_event(cmd)
      InvoiceRegistered.new(
        data: {
          store_id: cmd.store_id,
          invoice_id: cmd.invoice_id,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
