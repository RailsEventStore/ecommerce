module Infra
  module ProcessManager
    module ProcessMethods
      def initialize(event_store, command_bus)
        @event_store = event_store
        @command_bus = command_bus
      end

      def call(event)
        @state = initial_state
        @id = fetch_id(event)
        build_state(event)
        act
      end

      private

      attr_reader :event_store, :command_bus, :id, :state

      def build_state(event)
        projector_class = self.class.instance_variable_get(:@projector_class)
        raise "State projector class not found/configured for #{self.class}" unless projector_class
        with_retry do
          past_events = event_store.read.stream(stream_name).to_a
          last_stored_idx = past_events.empty? ? -1 : past_events.size - 1
          event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored_idx)

          current_projected_state = projector_class.initial_state_instance
          all_events_to_apply = past_events + [event]
          all_events_to_apply.uniq(&:event_id).each do |ev|
            current_projected_state = projector_class.apply(current_projected_state, ev)
          end
          @state = current_projected_state
        end
      end

      def stream_name
        "#{self.class.name}$#{id}"
      end
    end

    module Subscriptions
      def self.extended(host_class)
        host_class.instance_variable_set(:@subscribed_events, [])
      end

      def subscribes_to(*events)
        @subscribed_events += events
      end

      attr_reader :subscribed_events
    end

    def self.with_state(projector_class)
      unless projector_class && projector_class.respond_to?(:apply) && projector_class.respond_to?(:initial_state_instance)
        raise ArgumentError, "Projector class must be valid and respond to :apply and :initial_state_instance."
      end

      Module.new do
        @projector_class_config = projector_class
        define_method(:initial_state) do
          configured_projector = self.class.instance_variable_get(:@projector_class)
          raise "Projector class not found on #{self.class}" unless configured_projector
          configured_projector.initial_state_instance
        end

        def self.included(host_class)
          projector_to_set = @projector_class_config
          host_class.instance_variable_set(:@projector_class, projector_to_set)
          host_class.include(ProcessMethods)
          host_class.include(Infra::Retry)
          host_class.extend(Subscriptions)
        end
      end
    end
  end
end
