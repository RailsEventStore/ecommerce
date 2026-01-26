module Stores
  class Naming
    def initialize(event_store)
      @event_store = event_store
    end

    def call(cmd)
      @event_store.publish(store_named_event(cmd), stream_name: stream_name(cmd))
    end

    private

    def store_named_event(cmd)
      StoreNamed.new(
        data: {
          store_id: cmd.store_id,
          name: cmd.name.value,
        }
      )
    end

    def stream_name(cmd)
      "Stores::Store$#{cmd.store_id}"
    end
  end
end
