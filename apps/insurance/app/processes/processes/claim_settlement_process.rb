module Processes
  class ClaimSettlementProcess
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Policies::PolicyInForce,
      Policies::PolicyTerminated,
      Claims::LossAssessed,
      Claims::ClaimSettled
    )

    private

    def act
      command_bus.call(Claims::SettleClaim.new(claim_id: state.assessed_claim_id)) if payable?
    end

    def payable?
      state.policy_in_force && !state.assessed_claim_id.nil?
    end

    def apply(event)
      case event
      when Policies::PolicyInForce
        state.with(policy_in_force: true)
      when Policies::PolicyTerminated
        state.with(policy_in_force: false)
      when Claims::LossAssessed
        state.with(assessed_claim_id: event.data.fetch(:claim_id))
      when Claims::ClaimSettled
        state.with(assessed_claim_id: nil)
      end
    end

    def fetch_id(event)
      event.data.fetch(:policy_id)
    end

    ProcessState = Data.define(:policy_in_force, :assessed_claim_id) do
      def initialize(policy_in_force: false, assessed_claim_id: nil)
        super
      end
    end
  end
end
