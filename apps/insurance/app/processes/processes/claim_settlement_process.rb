module Processes
  class ClaimSettlementProcess
    include RubyEventStore::ProcessManager.with_state { ProcessState }

    subscribes_to(
      Policies::PolicyActivated,
      Policies::PolicyTerminated,
      Claims::LossAssessed,
      Claims::ClaimSettled
    )

    private

    def act
      command_bus.call(Claims::SettleClaim.new(claim_id: state.assessed_claim_id)) if payable?
    end

    def payable?
      state.policy_active && !state.assessed_claim_id.nil?
    end

    def apply(event)
      case event
      when Policies::PolicyActivated
        state.with(policy_active: true)
      when Policies::PolicyTerminated
        state.with(policy_active: false)
      when Claims::LossAssessed
        state.with(assessed_claim_id: event.data.fetch(:claim_id))
      when Claims::ClaimSettled
        state.with(assessed_claim_id: nil)
      end
    end

    def fetch_id(event)
      event.data.fetch(:policy_id)
    end

    ProcessState = Data.define(:policy_active, :assessed_claim_id) do
      def initialize(policy_active: false, assessed_claim_id: nil)
        super
      end
    end
  end
end
