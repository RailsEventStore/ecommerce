module Infra
  module ProcessRepository
    module ClassMethods
      def apply_event(&block)
        define_method(:apply_event) do |current_state, event|
          instance_exec(current_state, event, &block)
        end
      end
    end

    def self.included(host_class)
      host_class.extend(ClassMethods)
    end

    def build_from_events(initial_state, events)
      events.reduce(initial_state) do |state, event|
        apply_event(state, event)
      end
    end

    def new_state
      self.class.const_get(:ProcessState).new
    end
  end
end
