module Processes
  class CompensationProcess
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Policies::PolicyActivated,
      Policies::PolicyTerminated,
      Claims::DamageEvaluated,
      Claims::CompensationPaid
    )

    private

    def act
      command_bus.call(Claims::PayCompensation.new(claim_id: state.evaluated_claim_id)) if payable?
    end

    def payable?
      state.policy_active && !state.evaluated_claim_id.nil?
    end

    def apply(event)
      case event
      when Policies::PolicyActivated
        state.with(policy_active: true)
      when Policies::PolicyTerminated
        state.with(policy_active: false)
      when Claims::DamageEvaluated
        state.with(evaluated_claim_id: event.data.fetch(:claim_id))
      when Claims::CompensationPaid
        state.with(evaluated_claim_id: nil)
      end
    end

    def fetch_id(event)
      event.data.fetch(:policy_id)
    end

    ProcessState = Data.define(:policy_active, :evaluated_claim_id) do
      def initialize(policy_active: false, evaluated_claim_id: nil)
        super
      end
    end
  end
end
