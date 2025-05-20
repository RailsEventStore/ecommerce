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
        projector_class_block = self.class.instance_variable_get(:@projector_class_definition_block)
        unless projector_class_block
          raise "State projector class definition block not found for #{self.class}. "\
                "Ensure it's configured via Infra::ProcessManager.with_state { YourProjectorClass }."
        end

        projector_class = projector_class_block.call
        unless projector_class.is_a?(Class) &&
               projector_class.respond_to?(:apply) &&
               projector_class.respond_to?(:initial_state_instance)
          raise ArgumentError,
                "The block provided to with_state must return a valid Projector class " \
                "that responds to :apply and :initial_state_instance. Got: #{projector_class.inspect}"
        end

        with_retry do
          past_events = event_store.read.stream(stream_name).to_a
          last_stored_idx = past_events.empty? ? -1 : past_events.size - 1
          event_store.link(event.event_id, stream_name: stream_name, expected_version: last_stored_idx)

          current_projected_state = projector_class.initial_state_instance
          all_events_to_apply = past_events + [event]

          unique_events = all_events_to_apply.uniq(&:event_id)

          unique_events.each do |ev|
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

    def self.with_state(&projector_class_block)
      unless block_given?
        raise ArgumentError, "A block returning the projector class is required for with_state."
      end

      Module.new do
        @projector_class_definition_block_config = projector_class_block

        define_method(:initial_state) do
          block = self.class.instance_variable_get(:@projector_class_definition_block)
          unless block
            raise "Projector class definition block not found on #{self.class}. " \
                  "Was Infra::ProcessManager.with_state called with a block?"
          end

          projector_class = block.call
          unless projector_class.is_a?(Class) && projector_class.respond_to?(:initial_state_instance)
            raise "The block provided to with_state did not return a Class responding to :initial_state_instance. " \
                  "Got: #{projector_class.inspect}"
          end
          projector_class.initial_state_instance
        end

        def self.included(host_class)
          projector_block_to_set = @projector_class_definition_block_config
          host_class.instance_variable_set(:@projector_class_definition_block, projector_block_to_set)

          host_class.include(ProcessMethods)
          host_class.include(Infra::Retry)
          host_class.extend(Subscriptions)
        end
      end
    end
  end
end
