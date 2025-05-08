module Infra
  module ProcessManager
    module ProcessMethods
      def initialize(event_store, command_bus)
        @event_store = event_store
        @command_bus = command_bus
        repository_class = self.class.instance_variable_get(:@state_repository_class)
        raise "State repository class not configured for #{self.class}" unless repository_class
        @state_repository = repository_class.new
      end

      def call(event)
        @id = fetch_id(event)
        empty_state_instance = initial_state_from_definition
        @state = build_state_using_repository(empty_state_instance, event)
        act
      end

      private

      attr_reader :event_store, :command_bus, :id, :state_repository

      def initial_state_from_definition
        repository_class = self.class.instance_variable_get(:@state_repository_class)
        raise "State repository class not configured for #{self.class}" unless repository_class

        begin
          state_class = repository_class.const_get(:ProcessState)
        rescue NameError
          raise "Constant :ProcessState not found in repository class #{repository_class}"
        end

        raise "State class (ProcessState) retrieved from #{repository_class} is not a Class" unless state_class.is_a?(Class)
        state_class.new
      end

      def build_state_using_repository(initial_process_state, new_event)
        with_retry do
          past_events = event_store.read.stream(stream_name).to_a
          last_stored = past_events.size - 1
          event_store.link(new_event.event_id, stream_name:, expected_version: last_stored)

          all_events = past_events + [new_event]
          state_repository.build_from_events(initial_process_state, all_events)
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

    def self.with_state(state_repository_class: nil)
      unless state_repository_class.is_a?(Class)
        raise ArgumentError, "A state_repository_class (Class) is required."
      end

      Module.new do
        @repository_class_for_module = state_repository_class

        define_method(:state) do
          @state
        end

        def self.included(host_class)
          host_class.instance_variable_set(:@state_repository_class, @repository_class_for_module)

          host_class.include(ProcessMethods)
          host_class.include(Infra::Retry)
          host_class.extend(Subscriptions)
        end
      end
    end
  end
end
