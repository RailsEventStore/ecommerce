module Crm
  class Registration
    def initialize(cqrs)
      @cqrs = cqrs
    end

    def call(cmd)
      events = @cqrs.all_events_from_stream(stream_name(cmd))
      raise AlreadyRegistered unless events.empty?

      @cqrs.publish(customer_registered_event(cmd), stream_name(cmd))
    end

    private

    def customer_registered_event(cmd)
      CustomerRegistered.new(
        data: {
          customer_id: cmd.customer_id,
          name: cmd.name
        }
      )
    end

    def stream_name(cmd)
      "Crm::Customer$#{cmd.customer_id}"
    end
  end
end
