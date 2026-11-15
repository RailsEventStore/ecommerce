module Processes
  class JoinDefinition
    class TimeoutScheduled < RubyEventStore::Event
    end

    class TimedOut < RubyEventStore::Event
    end

    class Killed < RubyEventStore::Event
    end

    class State < Data.define(:events, :outcome)
      def initialize(events: {}, outcome: nil) = super
    end

    class Pattern < Data.define(:alternatives)
      def &(other)
        self.class.new(alternatives.product(other.alternatives).map { |left, right| left + right })
      end

      def |(other)
        self.class.new(alternatives + other.alternatives)
      end

      def matches?(events)
        alternatives.any? { |clause| clause.all? { |type| events.key?(type) } }
      end

      def to_s
        "(#{alternatives.map { |clause| clause.join(" & ") }.join(" | ")})"
      end
    end

    class Rule < Data.define(:pattern, :action, :blocked_by)
      def enabled?(events)
        pattern.matches?(events) && !blocked_by.matches?(events)
      end

      def specification
        "Given #{pattern}; unless #{blocked_by}; when an event arrives; then #{action}"
      end
    end

    def self.event(type)
      Pattern.new([[type]])
    end

    def initialize(rules, resets, completion)
      @rules, @resets, @completion = rules, resets, completion
    end

    def evolve(state, event, bounded = false)
      return state if state.outcome

      state.with(events: state.events.except(@resets[event.class]).merge(event.class => event)).then do |updated|
        updated.with(outcome: (outcome(updated, event) if bounded))
      end
    end

    def decide(state)
      return [] if state.outcome

      @rules.select { |rule| rule.enabled?(state.events) }.take(1).map(&:action)
    end

    def specification
      (@rules.map(&:specification) + [
        "Completed on #{@completion}",
        "TimedOut on #{TimedOut}",
        "Killed on #{Killed}"
      ]).join("\n")
    end

    private

    def outcome(state, event)
      case event
      when TimedOut
        :TimedOut
      when Killed
        :Killed
      else
        :Completed if @completion.matches?(state.events)
      end
    end
  end
end
