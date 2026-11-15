module Processes
  module JoinProcess
    def with_timeout(seconds, scheduler)
      raise ArgumentError unless seconds.finite? && seconds.positive?

      @timeout, @scheduler = seconds, scheduler
      self
    end

    private

    def apply(event)
      self.class::Definition.evolve(state, event, @timeout)
    end

    def act
      schedule_timeout if @timeout && !state.outcome && !state.events.key?(JoinDefinition::TimeoutScheduled)
      self.class::Definition.decide(state).each { |action| __send__(action) }
    end

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def stream_name
      @timeout ? "#{self.class}::Bounded$#{id}" : super
    end

    def schedule_timeout
      record_timeout(JoinDefinition::TimeoutScheduled.new(data: {
        order_id: id,
        seconds: @timeout,
        timeout_event_id: SecureRandom.uuid
      }))
    end

    def record_timeout(event)
      event_store.append(event, stream_name: stream_name, expected_version: :auto)
      @state = apply(event)
      @scheduler.call(
        JoinDefinition::TimedOut.new(
          event_id: event.data.fetch(:timeout_event_id),
          data: { order_id: id, process: self.class.name }
        ),
        stream_name,
        event.data.fetch(:seconds)
      )
    end
  end
end
